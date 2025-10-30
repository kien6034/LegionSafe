// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/LegionSafe.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./ForkTestBase.sol";
import "./addresses/BSC.sol";
import "./interfaces/IKyberSwapRouter.sol";
import "./helpers/KyberSwapHelper.sol";

/// @notice Fork test for LegionSafe integration with KyberSwap on BSC
contract LegionSafe_KyberSwap_BSC_Test is ForkTestBase {
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

        // Label addresses for better traces
        vm.label(address(safe), "LegionSafe");
        vm.label(BSC.KYBER_ROUTER, "KyberRouter");
        vm.label(BSC.USDT, "USDT");
        vm.label(BSC.WBNB, "WBNB");
        vm.label(owner, "Owner");
        vm.label(operator, "Operator");

        // Fund safe with BNB
        vm.deal(address(safe), 10 ether);

        // Authorize KyberSwap router swapSimpleMode function
        bytes4 swapSelector = IKyberSwapRouter.swapSimpleMode.selector;
        vm.prank(owner);
        safe.setCallAuthorization(BSC.KYBER_ROUTER, swapSelector, true);
    }

    function testForkSetup() public {
        // Verify fork is active
        assertEq(block.chainid, BSC.CHAIN_ID);

        // Verify safe is funded
        assertEq(address(safe).balance, 10 ether);

        // Verify router function is authorized
        bytes4 swapSelector = IKyberSwapRouter.swapSimpleMode.selector;
        assertTrue(safe.authorizedCalls(BSC.KYBER_ROUTER, swapSelector));

        // Verify operator is set correctly
        assertEq(safe.operator(), operator);
    }

    /// @notice Template test for BNB to USDT swap - REQUIRES REAL API DATA
    /// @dev This test is skipped because KyberSwap requires real route data from their API.
    /// To use this test:
    /// 1. Get route data from KyberSwap API (https://aggregator-api.kyberswap.com/bsc/api/v1/routes)
    /// 2. Build transaction data from the API response
    /// 3. Replace the swapCalldata below with the actual API calldata
    /// 4. Remove the vm.skip() line
    function testSwapBNBToUSDT() public {
        vm.skip(true); // Skip this test - requires real API data

        uint256 swapAmount = 1 ether; // Swap 1 BNB
        uint256 minUSDTOut = 500e18; // Expect at least 500 USDT (adjust based on price)

        // Record initial balances
        uint256 initialBNB = address(safe).balance;
        uint256 initialUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        console.log("Initial BNB:", initialBNB);
        console.log("Initial USDT:", initialUSDT);

        // NOTE: This helper builds calldata with empty executorData which won't work
        // with real KyberSwap router. You need to get real route data from the API.
        // See test/fork/LegionSafe_KyberSwap_API.t.sol for API-based testing template
        bytes memory swapCalldata = KyberSwapHelper.buildSimpleSwapCalldata(
            BSC.USDT,
            address(safe),
            swapAmount,
            minUSDTOut
        );

        // Execute swap via manage function
        vm.prank(operator);
        bytes memory result = safe.manage(
            BSC.KYBER_ROUTER,
            swapCalldata,
            swapAmount // Send BNB with the call
        );

        // Decode return value (amount of USDT received)
        uint256 usdtReceived = abi.decode(result, (uint256));

        // Verify balances changed
        uint256 finalBNB = address(safe).balance;
        uint256 finalUSDT = IERC20(BSC.USDT).balanceOf(address(safe));

        console.log("Final BNB:", finalBNB);
        console.log("Final USDT:", finalUSDT);
        console.log("USDT Received:", usdtReceived);

        // Assertions
        assertEq(finalBNB, initialBNB - swapAmount, "BNB not deducted");
        assertGt(finalUSDT, initialUSDT, "USDT not received");
        assertGe(finalUSDT - initialUSDT, minUSDTOut, "USDT below minimum");
        assertEq(finalUSDT - initialUSDT, usdtReceived, "Return value mismatch");
    }

    function testSwapBNBToUSDT_RevertWhen_NotOperator() public {
        uint256 swapAmount = 1 ether;
        uint256 minUSDTOut = 500e18;

        bytes memory swapCalldata = KyberSwapHelper.buildSimpleSwapCalldata(
            BSC.USDT,
            address(safe),
            swapAmount,
            minUSDTOut
        );

        // Try to execute as non-operator
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert(LegionSafe.Unauthorized.selector);
        safe.manage(BSC.KYBER_ROUTER, swapCalldata, swapAmount);
    }

    /// @notice Test swap with unauthorized router (not authorized)
    function testSwapBNBToUSDT_RevertWhen_RouterNotAuthorized() public {
        uint256 swapAmount = 1 ether;
        uint256 minUSDTOut = 500e18;

        bytes memory swapCalldata = KyberSwapHelper.buildSimpleSwapCalldata(
            BSC.USDT,
            address(safe),
            swapAmount,
            minUSDTOut
        );

        // Revoke authorization
        bytes4 swapSelector = IKyberSwapRouter.swapSimpleMode.selector;
        vm.prank(owner);
        safe.setCallAuthorization(BSC.KYBER_ROUTER, swapSelector, false);

        // Try to execute as operator but without authorization
        vm.prank(operator);
        vm.expectRevert(LegionSafe.CallNotAuthorized.selector);
        safe.manage(BSC.KYBER_ROUTER, swapCalldata, swapAmount);
    }
}
