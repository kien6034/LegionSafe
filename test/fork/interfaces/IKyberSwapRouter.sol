// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Interface for KyberSwap MetaAggregationRouterV2
/// @dev Simplified interface for testing - only includes swap function
interface IKyberSwapRouter {
    struct SwapExecutorDescription {
        address swapExecutor;
        address tokenIn;
        address tokenOut;
        address to;
        uint256 deadline;
        bytes positiveSlippageData;
    }

    struct SwapDescription {
        address srcToken;
        address dstToken;
        address[] srcReceivers;
        uint256[] srcAmounts;
        address[] feeReceivers;
        uint256[] feeAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /// @notice Execute swap
    /// @param executor Executor description
    /// @param desc Swap description
    /// @param executorData Executor-specific data
    /// @param clientData Client data for tracking
    function swap(
        SwapExecutorDescription calldata executor,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external payable returns (uint256 returnAmount);

    /// @notice Simpler swap function for native token swaps
    function swapSimpleMode(
        address caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external payable returns (uint256 returnAmount);
}
