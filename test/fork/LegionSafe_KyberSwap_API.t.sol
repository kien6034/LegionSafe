// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/LegionSafe.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./ForkTestBase.sol";
import "./addresses/BSC.sol";
import "./interfaces/IKyberSwapRouter.sol";

/// @notice Fork test using real KyberSwap API data
/// @dev This test requires manual API call to get route data
///
/// HOW TO USE THIS TEST:
/// ====================
/// 1. Get a route from KyberSwap Aggregator API:
///    curl "https://aggregator-api.kyberswap.com/bsc/api/v1/routes?tokenIn=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&tokenOut=0x55d398326f99059fF775485246999027B3197955&amountIn=1000000000000000000"
///
/// 2. Build the swap transaction:
///    curl -X POST "https://aggregator-api.kyberswap.com/bsc/api/v1/route/build" \
///      -H "Content-Type: application/json" \
///      -d '{"routeSummary": <ROUTE_FROM_STEP_1>, "sender": "<LEGION_SAFE_ADDRESS>", "recipient": "<LEGION_SAFE_ADDRESS>"}'
///
/// 3. Extract the calldata from the response (the "data" field)
///
/// 4. Paste the calldata into the test below (replace the hex"..." placeholder)
///
/// 5. Run the test:
///    forge test --match-test testSwapWithRealAPIData --fork-url https://bsc-dataseed1.binance.org -vvvv
///
contract LegionSafe_KyberSwap_API_Test is ForkTestBase {
    LegionSafe public safe;

    address public owner;
    address public operator;

    uint256 public bscFork;

    function setUp() public {
        // Create BSC fork
        bscFork = createAndSelectFork(BSC.RPC_URL);

        // Setup accounts
        owner = makeAddr("owner");
        operator = makeAddr("operator");

        // Deploy LegionSafe using proxy pattern
        LegionSafe implementation = new LegionSafe();
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            operator
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        safe = LegionSafe(payable(address(proxy)));

        // Label addresses
        vm.label(address(safe), "LegionSafe");
        vm.label(BSC.KYBER_ROUTER, "KyberRouter");
        vm.label(BSC.USDT, "USDT");

        // Fund safe with BNB
        vm.deal(address(safe), 10 ether);

        // Authorize KyberSwap router - authorize both swap functions
        vm.startPrank(owner);
        safe.setCallAuthorization(BSC.KYBER_ROUTER, IKyberSwapRouter.swap.selector, true);
        safe.setCallAuthorization(BSC.KYBER_ROUTER, IKyberSwapRouter.swapSimpleMode.selector, true);
        vm.stopPrank();
    }

    /// @notice Test swap using real API data
    /// @dev This test is skipped by default - enable it when you have real API calldata
    function testSwapWithRealAPIData() public {
        vm.skip(true); // Remove this line when you have real API data

        // STEP 1: Replace this with actual calldata from KyberSwap API
        // Example format:
        // bytes memory apiCalldata = hex"8af033fb..."; // Full calldata from API /route/build endpoint
        bytes memory apiCalldata = hex""; // <-- PASTE API CALLDATA HERE

        // STEP 2: Set the swap amount (should match the amount used in API call)
        uint256 swapAmount = 1 ether;

        // Record initial balances
        uint256 initialBNB = address(safe).balance;
        uint256 initialUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        console.log("=== Initial State ===");
        console.log("BNB Balance:", initialBNB);
        console.log("USDT Balance:", initialUSDT);

        // Execute swap via manage function
        vm.prank(operator);
        bytes memory result = safe.manage(
            BSC.KYBER_ROUTER,
            apiCalldata,
            swapAmount // Send BNB with the call
        );

        // Decode return value (amount of USDT received)
        uint256 usdtReceived = abi.decode(result, (uint256));

        // Record final balances
        uint256 finalBNB = address(safe).balance;
        uint256 finalUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        console.log("\n=== Final State ===");
        console.log("BNB Balance:", finalBNB);
        console.log("USDT Balance:", finalUSDT);
        console.log("\n=== Swap Results ===");
        console.log("BNB Spent:", initialBNB - finalBNB);
        console.log("USDT Received:", usdtReceived);
        console.log("USDT Balance Change:", finalUSDT - initialUSDT);

        // Assertions
        assertEq(finalBNB, initialBNB - swapAmount, "BNB not deducted correctly");
        assertGt(finalUSDT, initialUSDT, "USDT not received");
        assertEq(finalUSDT - initialUSDT, usdtReceived, "Return value mismatch");
    }

    /// @notice Example test showing how to verify specific API response
    /// @dev Useful for testing with known API responses
    function testSwapWithKnownAPIResponse() public {
        vm.skip(true); // Remove this when you have a specific API response to test

        // Example: You got a quote from API that says 1 BNB = ~600 USDT
        // You can hardcode the expected output and verify the swap works

        bytes memory apiCalldata = hex""; // <-- PASTE API CALLDATA HERE
        uint256 swapAmount = 1 ether;
        uint256 expectedMinUSDT = 590e18; // Expect at least 590 USDT (allow some slippage)

        uint256 initialUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        vm.prank(operator);
        bytes memory result = safe.manage(BSC.KYBER_ROUTER, apiCalldata, swapAmount);

        uint256 usdtReceived = abi.decode(result, (uint256));
        uint256 finalUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        // Verify minimum output
        assertGe(usdtReceived, expectedMinUSDT, "USDT received below minimum");
        assertEq(finalUSDT - initialUSDT, usdtReceived, "Balance mismatch");
    }
}
