// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "../interfaces/IKyberSwapRouter.sol";
import "forge-std/Test.sol";

/// @notice Helper for building KyberSwap swap calldata
/// @dev Simplifies creating swap parameters for testing
library KyberSwapHelper {
    /// @notice Build simple swap calldata for BNB -> Token
    /// @dev For native token input, srcToken should be 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    function buildSimpleSwapCalldata(
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal pure returns (bytes memory) {
        // Native token indicator for KyberSwap
        address NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        IKyberSwapRouter.SwapDescription memory desc = IKyberSwapRouter.SwapDescription({
            srcToken: NATIVE_TOKEN,
            dstToken: tokenOut,
            srcReceivers: new address[](0),
            srcAmounts: new uint256[](0),
            feeReceivers: new address[](0),
            feeAmounts: new uint256[](0),
            dstReceiver: recipient,
            amount: amountIn,
            minReturnAmount: minAmountOut,
            flags: 0,
            permit: ""
        });

        // For simple mode, we can use empty executor data
        // In production, this would come from the API
        bytes memory executorData = "";
        bytes memory clientData = "";

        return abi.encodeCall(
            IKyberSwapRouter.swapSimpleMode,
            (address(0), desc, executorData, clientData)
        );
    }

    /// @notice Calculate minimum amount out with slippage
    /// @param amountOut Expected output amount
    /// @param slippageBps Slippage in basis points (50 = 0.5%)
    function calculateMinAmountOut(
        uint256 amountOut,
        uint256 slippageBps
    ) internal pure returns (uint256) {
        return (amountOut * (10000 - slippageBps)) / 10000;
    }
}

contract KyberSwapHelperTest is Test {
    function testCalculateMinAmountOut() public {
        uint256 amountOut = 1000e18;
        uint256 slippage = 50; // 0.5%
        uint256 minOut = KyberSwapHelper.calculateMinAmountOut(amountOut, slippage);
        assertEq(minOut, 995e18); // 1000 - 0.5%
    }
}
