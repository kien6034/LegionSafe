// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title LegionSafe
 * @notice A secure vault for managing crypto meme trading automation with role-based access control
 * @dev Implements UUPS upgradeability with two-step ownership transfer
 *      - Operator: Can trigger arbitrary payloads through manage()
 *      - Owner: Has exclusive rights to withdraw funds and authorize upgrades
 */
contract LegionSafe is
    Initializable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    // State variables
    address public operator;

    // Mapping to track authorized function signatures for specific target contracts
    mapping(address => mapping(bytes4 => bool)) public authorizedCalls;

    // Events
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event CallAuthorized(address indexed target, bytes4 indexed selector, bool authorized);
    event Managed(address indexed target, uint256 value, bytes data);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event EthReceived(address indexed sender, uint256 amount);
    event ManagedBatch(address[] targets, bytes[] data, uint256[] values);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error CallNotAuthorized();
    error CallFailed(bytes returnData);
    error WithdrawalFailed();
    error InvalidAmount();
    error InvalidInput();

    // Modifiers
    modifier onlyOperator() {
        if (msg.sender != operator) revert Unauthorized();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the LegionSafe contract
     * @dev Replaces constructor for proxy pattern. Can only be called once.
     * @param _owner Address of the owner who can withdraw funds and authorize upgrades
     * @param _operator Address of the operator who can execute trades
     */
    function initialize(address _owner, address _operator) public initializer {
        if (_owner == address(0) || _operator == address(0)) revert InvalidAddress();

        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        operator = _operator;
        emit OperatorChanged(address(0), _operator);
    }

    /**
     * @notice Change the operator address
     * @param newOperator Address of the new operator
     */
    function setOperator(address newOperator) external onlyOwner {
        if (newOperator == address(0)) revert InvalidAddress();
        address oldOperator = operator;
        operator = newOperator;
        emit OperatorChanged(oldOperator, newOperator);
    }

    /**
     * @notice Authorize or revoke authorization for a specific function call on a target contract
     * @param target The contract address to authorize calls to
     * @param selector The function selector (first 4 bytes of keccak256 of function signature)
     * @param authorized Whether to authorize (true) or revoke (false) the call
     */
    function setCallAuthorization(address target, bytes4 selector, bool authorized) external onlyOwner {
        if (target == address(0)) revert InvalidAddress();
        authorizedCalls[target][selector] = authorized;
        emit CallAuthorized(target, selector, authorized);
    }

    /**
     * @notice Execute an arbitrary call to an external contract (operator only)
     * @dev Validates authorization before executing the call
     * @param target The contract address to call
     * @param data The calldata to send
     * @param value The amount of ETH to send with the call
     */
    function manage(address target, bytes calldata data, uint256 value)
        public
        onlyOperator
        nonReentrant
        returns (bytes memory)
    {
        if (target == address(0)) revert InvalidAddress();
        if (data.length < 4) revert CallNotAuthorized();

        // Extract function selector from calldata
        bytes4 selector = bytes4(data[:4]);

        // Check if this call is authorized
        if (!authorizedCalls[target][selector]) revert CallNotAuthorized();

        // Execute the call
        (bool success, bytes memory returnData) = target.call{value: value}(data);

        if (!success) {
            revert CallFailed(returnData);
        }

        emit Managed(target, value, data);
        return returnData;
    }

    
    /**
     * @notice Execute a batch of managed calls to external contracts (operator only)
     * @dev Validates authorization before executing the calls
     * @param targets The contract addresses to call
     * @param data The calldata to send
     * @param values The amount of ETH to send with the calls
     */
    function manageBatch(address[] calldata targets, bytes[] calldata data, uint256[] calldata values)
        external
        onlyOperator
        nonReentrant
        returns (bytes[] memory)
    {
        if (targets.length != data.length || targets.length != values.length) revert InvalidInput();

        bytes[] memory returnData = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            returnData[i] = manage(targets[i], data[i], values[i]);
        }

        emit ManagedBatch(targets, data, values);
        return returnData;
    }

    /**
     * @notice Withdraw ETH from the contract to the owner (owner only)
     * @param amount Amount of ETH to withdraw
     */
    function withdrawETH(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (amount > address(this).balance) revert InvalidAmount();

        address payable ownerAddr = payable(owner());
        (bool success, ) = ownerAddr.call{value: amount}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawn(address(0), ownerAddr, amount);
    }

    /**
     * @notice Withdraw ERC20 tokens from the contract to the owner (owner only)
     * @param token The ERC20 token contract address
     * @param amount Amount of tokens to withdraw
     */
    function withdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        address ownerAddr = owner();
        IERC20(token).safeTransfer(ownerAddr, amount);

        emit Withdrawn(token, ownerAddr, amount);
    }

    /**
     * @notice Withdraw all ETH from the contract to the owner (owner only)
     */
    function withdrawAllETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InvalidAmount();

        address payable ownerAddr = payable(owner());
        (bool success, ) = ownerAddr.call{value: balance}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawn(address(0), ownerAddr, balance);
    }

    /**
     * @notice Withdraw all ERC20 tokens from the contract to the owner (owner only)
     * @param token The ERC20 token contract address
     */
    function withdrawAllERC20(address token) external onlyOwner nonReentrant {
        if (token == address(0)) revert InvalidAddress();

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert InvalidAmount();

        address ownerAddr = owner();
        IERC20(token).safeTransfer(ownerAddr, balance);

        emit Withdrawn(token, ownerAddr, balance);
    }

    /**
     * @notice Receive function to accept ETH deposits
     */
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /**
     * @notice Fallback function to accept ETH deposits
     */
    fallback() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /**
     * @notice Get the ETH balance of the contract
     * @return The ETH balance in wei
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get the ERC20 token balance of the contract
     * @param token The ERC20 token contract address
     * @return The token balance
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Authorize upgrade to new implementation (UUPS pattern)
     * @dev Only owner can authorize upgrades. This is called by upgradeToAndCall.
     * @param newImplementation Address of new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
