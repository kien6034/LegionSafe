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

    // Constants
    bytes4 public constant APPROVE_SELECTOR = 0x095ea7b3; // approve(address,uint256)
    uint256 public constant SPENDING_WINDOW_DURATION = 6 hours;

    // Structs
    struct SpendingLimit {
        uint256 limitPerWindow;    // Max amount per 6-hour window
        uint256 spent;              // Amount spent in current window
        uint256 lastWindowStart;    // Start of the window when last spend occurred
    }

    // State variables
    address public operator;

    // Mapping to track authorized function signatures for specific target contracts
    mapping(address => mapping(bytes4 => bool)) public authorizedCalls;

    // Whitelist for approve operations
    mapping(address => bool) public whitelistedSpenders;

    // Spending limits by token address (address(0) = native token ETH/BNB)
    mapping(address => SpendingLimit) public spendingLimits;

    // List of tokens to track spending for
    address[] public trackedTokens;

    // Events
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event CallAuthorized(address indexed target, bytes4 indexed selector, bool authorized);
    event Managed(address indexed target, uint256 value, bytes data);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event EthReceived(address indexed sender, uint256 amount);
    event ManagedBatch(address[] targets, bytes[] data, uint256[] values);
    event SpenderWhitelisted(address indexed spender, bool whitelisted);
    event SpendingLimitSet(address indexed token, uint256 limitPerWindow);
    event SpendingTracked(address indexed token, uint256 amount, uint256 totalSpent);
    event TrackedTokenAdded(address indexed token);
    event TrackedTokenRemoved(address indexed token);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error CallNotAuthorized();
    error CallFailed(bytes returnData);
    error WithdrawalFailed();
    error InvalidAmount();
    error InvalidInput();
    error SpenderNotWhitelisted();
    error SpendingLimitExceeded(address token, uint256 amount, uint256 limit);
    error TokenAlreadyTracked();
    error TokenNotTracked();

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
     * @notice Whitelist or remove a spender address for ERC20 approve operations
     * @param spender The address to whitelist (e.g., DEX router)
     * @param whitelisted Whether to whitelist (true) or remove (false) the spender
     */
    function setSpenderWhitelist(address spender, bool whitelisted) external onlyOwner {
        if (spender == address(0)) revert InvalidAddress();
        whitelistedSpenders[spender] = whitelisted;
        emit SpenderWhitelisted(spender, whitelisted);
    }

    /**
     * @notice Add a token to the spending tracking list
     * @param token The token address to track (use address(0) for native token)
     */
    function addTrackedToken(address token) external onlyOwner {
        // Check not already added
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            if (trackedTokens[i] == token) revert TokenAlreadyTracked();
        }
        trackedTokens.push(token);
        emit TrackedTokenAdded(token);
    }

    /**
     * @notice Remove a token from the spending tracking list
     * @param token The token address to remove from tracking
     */
    function removeTrackedToken(address token) external onlyOwner {
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            if (trackedTokens[i] == token) {
                // Swap with last element and pop
                trackedTokens[i] = trackedTokens[trackedTokens.length - 1];
                trackedTokens.pop();
                emit TrackedTokenRemoved(token);
                return;
            }
        }
        revert TokenNotTracked();
    }

    /**
     * @notice Get the list of tracked tokens
     * @return Array of tracked token addresses
     */
    function getTrackedTokens() external view returns (address[] memory) {
        return trackedTokens;
    }

    /**
     * @notice Set spending limit for a token
     * @param token The token address (use address(0) for native token)
     * @param limitPerWindow Maximum amount that can be spent per 6-hour window
     */
    function setSpendingLimit(address token, uint256 limitPerWindow) external onlyOwner {
        spendingLimits[token] = SpendingLimit({
            limitPerWindow: limitPerWindow,
            spent: 0,
            lastWindowStart: (block.timestamp / SPENDING_WINDOW_DURATION) * SPENDING_WINDOW_DURATION
        });
        emit SpendingLimitSet(token, limitPerWindow);
    }

    /**
     * @notice Get remaining spending limit for a token in the current window
     * @param token The token address to check
     * @return remaining Amount remaining that can be spent in current window
     * @return windowEndsAt Timestamp when the current window ends
     */
    function getRemainingLimit(address token) external view returns (
        uint256 remaining,
        uint256 windowEndsAt
    ) {
        SpendingLimit storage limit = spendingLimits[token];

        if (limit.limitPerWindow == 0) {
            return (0, 0); // No limit configured
        }

        uint256 currentWindowStart = (block.timestamp / SPENDING_WINDOW_DURATION) * SPENDING_WINDOW_DURATION;

        // If new window, full limit available
        if (currentWindowStart > limit.lastWindowStart) {
            return (
                limit.limitPerWindow,
                currentWindowStart + SPENDING_WINDOW_DURATION
            );
        }

        // Current window
        remaining = limit.limitPerWindow > limit.spent
            ? limit.limitPerWindow - limit.spent
            : 0;
        windowEndsAt = currentWindowStart + SPENDING_WINDOW_DURATION;

        return (remaining, windowEndsAt);
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

        bytes4 selector = bytes4(data[:4]);

        // Special case: approve function
        if (selector == APPROVE_SELECTOR) {
            // Extract spender from calldata (bytes 4-36 = address parameter)
            address spender = address(uint160(uint256(bytes32(data[4:36]))));

            // Check if spender is whitelisted
            if (!whitelistedSpenders[spender]) revert SpenderNotWhitelisted();

            // Allow approve on any token (target) to whitelisted spender
            // No spending limit check for approvals (just authorization)
        } else {
            // Normal path: check target+selector authorization
            if (!authorizedCalls[target][selector]) revert CallNotAuthorized();
        }

        // Snapshot balances before call
        uint256[] memory balancesBefore = _snapshotBalances();

        // Execute the call
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        if (!success) revert CallFailed(returnData);

        // Check spending limits based on balance changes
        _checkSpendingLimits(balancesBefore);

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
     * @notice Internal function to check and update spending limit for a token
     * @param token The token address
     * @param amount The amount being spent
     */
    function _checkAndUpdateLimit(address token, uint256 amount) internal {
        SpendingLimit storage limit = spendingLimits[token];

        if (limit.limitPerWindow == 0) return; // No limit configured

        // Calculate current window start (aligned to 6-hour blocks)
        uint256 currentWindowStart = (block.timestamp / SPENDING_WINDOW_DURATION) * SPENDING_WINDOW_DURATION;

        // Reset if we're in a new window
        if (currentWindowStart > limit.lastWindowStart) {
            limit.spent = 0;
            limit.lastWindowStart = currentWindowStart;
        }

        // Check limit
        if (limit.spent + amount > limit.limitPerWindow) {
            revert SpendingLimitExceeded(token, amount, limit.limitPerWindow);
        }

        // Update spent amount
        limit.spent += amount;
        emit SpendingTracked(token, amount, limit.spent);
    }

    /**
     * @notice Internal function to snapshot balances before a call
     * @return Array of balances for tracked tokens
     */
    function _snapshotBalances() internal view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](trackedTokens.length);
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            if (trackedTokens[i] == address(0)) {
                balances[i] = address(this).balance;
            } else {
                balances[i] = IERC20(trackedTokens[i]).balanceOf(address(this));
            }
        }
        return balances;
    }

    /**
     * @notice Internal function to check spending limits after a call
     * @param balancesBefore Array of balances before the call
     */
    function _checkSpendingLimits(uint256[] memory balancesBefore) internal {
        for (uint256 i = 0; i < trackedTokens.length; i++) {
            uint256 balanceAfter;
            if (trackedTokens[i] == address(0)) {
                balanceAfter = address(this).balance;
            } else {
                balanceAfter = IERC20(trackedTokens[i]).balanceOf(address(this));
            }

            // If balance decreased, track as spending
            if (balanceAfter < balancesBefore[i]) {
                uint256 spent = balancesBefore[i] - balanceAfter;
                _checkAndUpdateLimit(trackedTokens[i], spent);
            }
        }
    }

    /**
     * @notice Authorize upgrade to new implementation (UUPS pattern)
     * @dev Only owner can authorize upgrades. This is called by upgradeToAndCall.
     * @param newImplementation Address of new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
