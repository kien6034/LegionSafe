// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LegionSafe
 * @notice A secure vault for managing crypto meme trading automation with role-based access control
 * @dev Implements operator-controlled transaction execution and owner-controlled fund withdrawal
 */
contract LegionSafe is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public owner;
    address public operator;

    // Mapping to track authorized function signatures for specific target contracts
    mapping(address => mapping(bytes4 => bool)) public authorizedCalls;

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event CallAuthorized(address indexed target, bytes4 indexed selector, bool authorized);
    event Managed(address indexed target, uint256 value, bytes data);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event EthReceived(address indexed sender, uint256 amount);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error CallNotAuthorized();
    error CallFailed(bytes returnData);
    error WithdrawalFailed();
    error InvalidAmount();

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyOperator() {
        if (msg.sender != operator) revert Unauthorized();
        _;
    }

    /**
     * @notice Constructor to initialize the LegionSafe contract
     * @param _owner Address of the owner who can withdraw funds
     * @param _operator Address of the operator who can execute trades
     */
    constructor(address _owner, address _operator) {
        if (_owner == address(0) || _operator == address(0)) revert InvalidAddress();

        owner = _owner;
        operator = _operator;

        emit OwnershipTransferred(address(0), _owner);
        emit OperatorChanged(address(0), _operator);
    }

    /**
     * @notice Transfer ownership to a new address
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        external
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
     * @notice Withdraw ETH from the contract (owner only)
     * @param to Address to send the ETH to
     * @param amount Amount of ETH to withdraw
     */
    function withdrawETH(address payable to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        if (amount > address(this).balance) revert InvalidAmount();

        (bool success, ) = to.call{value: amount}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawn(address(0), to, amount);
    }

    /**
     * @notice Withdraw ERC20 tokens from the contract (owner only)
     * @param token The ERC20 token contract address
     * @param to Address to send the tokens to
     * @param amount Amount of tokens to withdraw
     */
    function withdrawERC20(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        if (token == address(0) || to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        IERC20(token).safeTransfer(to, amount);

        emit Withdrawn(token, to, amount);
    }

    /**
     * @notice Withdraw all ETH from the contract (owner only)
     * @param to Address to send the ETH to
     */
    function withdrawAllETH(address payable to) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        uint256 balance = address(this).balance;
        if (balance == 0) revert InvalidAmount();

        (bool success, ) = to.call{value: balance}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawn(address(0), to, balance);
    }

    /**
     * @notice Withdraw all ERC20 tokens from the contract (owner only)
     * @param token The ERC20 token contract address
     * @param to Address to send the tokens to
     */
    function withdrawAllERC20(address token, address to) external onlyOwner nonReentrant {
        if (token == address(0) || to == address(0)) revert InvalidAddress();

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert InvalidAmount();

        IERC20(token).safeTransfer(to, balance);

        emit Withdrawn(token, to, balance);
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
}
