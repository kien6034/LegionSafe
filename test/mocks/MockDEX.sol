// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockDEX
 * @notice A simple mock DEX for testing trade execution
 * @dev Simulates a basic swap function that exchanges tokens at a fixed rate
 */
contract MockDEX {
    using SafeERC20 for IERC20;

    // Events
    event Swap(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    // Simple swap function that exchanges tokenIn for tokenOut
    // For testing purposes, uses a 1:1 exchange rate
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");

        // Transfer tokens from sender
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calculate output amount (1:1 ratio for simplicity)
        amountOut = amountIn;
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Transfer output tokens to sender
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);

        return amountOut;
    }

    // Function to swap ETH for tokens
    function swapETHForTokens(
        address tokenOut,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut) {
        require(msg.value > 0, "Must send ETH");

        // Calculate output amount (1:1 ratio for simplicity)
        amountOut = msg.value;
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Transfer output tokens to sender
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(0), tokenOut, msg.value, amountOut);

        return amountOut;
    }

    // Function to swap tokens for ETH
    function swapTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");

        // Transfer tokens from sender
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        // Calculate output amount (1:1 ratio for simplicity)
        amountOut = amountIn;
        require(amountOut >= minAmountOut, "Insufficient output amount");
        require(address(this).balance >= amountOut, "Insufficient ETH balance");

        // Transfer ETH to sender
        (bool success, ) = msg.sender.call{value: amountOut}("");
        require(success, "ETH transfer failed");

        emit Swap(msg.sender, tokenIn, address(0), amountIn, amountOut);

        return amountOut;
    }

    // Helper function to add liquidity for testing
    function addLiquidity(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    // Receive ETH
    receive() external payable {}
}
