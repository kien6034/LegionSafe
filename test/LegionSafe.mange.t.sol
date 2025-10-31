// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LegionSafe.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockDEX.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LegionSafeManageTest is Test {
    LegionSafe public vault;
    LegionSafe public implementation;
    ERC1967Proxy public proxy;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockDEX public dex;

    address public owner;
    address public operator;
    address public unauthorized;

    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event CallAuthorized(address indexed target, bytes4 indexed selector, bool authorized);
    event Managed(address indexed target, uint256 value, bytes data);

    function setUp() public {
        owner = address(0x1);
        operator = address(0x2);
        unauthorized = address(0x3);

        implementation = new LegionSafe();

        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            operator
        );

        proxy = new ERC1967Proxy(address(implementation), initData);

        vault = LegionSafe(payable(address(proxy)));

        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        dex = new MockDEX();

        tokenA.mint(address(vault), 1000 * 10 ** 18);
        tokenB.mint(address(vault), 1000 * 10 ** 18);
        vm.deal(address(vault), 10 ether);

        tokenA.mint(address(dex), 1000000 * 10 ** 18);
        tokenB.mint(address(dex), 1000000 * 10 ** 18);
        vm.deal(address(dex), 1000 ether);
    }

    // ====================================
    // Manage Function Tests
    // ====================================

    function test_ManageSuccessfulCall() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.prank(owner);
        vault.setCallAuthorization(address(dex), selector, true);

        vm.prank(owner);
        vault.setSpenderWhitelist(address(dex), true);

        uint256 amountIn = 100 * 10 ** 18;
        bytes memory data = abi.encodeWithSelector(
            selector,
            address(tokenA),
            address(tokenB),
            amountIn,
            amountIn
        );

        uint256 vaultTokenABefore = tokenA.balanceOf(address(vault));
        uint256 vaultTokenBBefore = tokenB.balanceOf(address(vault));

        vm.startPrank(operator);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, address(dex), amountIn),
            0
        );
        vm.expectEmit(true, false, false, false);
        emit Managed(address(dex), 0, data);
        vault.manage(address(dex), data, 0);
        vm.stopPrank();

        assertLt(tokenA.balanceOf(address(vault)), vaultTokenABefore);
        assertGt(tokenB.balanceOf(address(vault)), vaultTokenBBefore);
    }

    function test_RevertManageUnauthorizedCaller() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        vm.prank(owner);
        vault.setCallAuthorization(address(dex), selector, true);

        bytes memory data = abi.encodeWithSelector(
            selector,
            address(tokenA),
            address(tokenB),
            100 * 10 ** 18,
            100 * 10 ** 18
        );

        vm.prank(unauthorized);
        vm.expectRevert(LegionSafe.Unauthorized.selector);
        vault.manage(address(dex), data, 0);
    }

    function test_RevertManageUnauthorizedFunction() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes memory data = abi.encodeWithSelector(
            selector,
            address(tokenA),
            address(tokenB),
            100 * 10 ** 18,
            100 * 10 ** 18
        );

        vm.prank(operator);
        vm.expectRevert(LegionSafe.CallNotAuthorized.selector);
        vault.manage(address(dex), data, 0);
    }

    function test_RevertManageZeroAddress() public {
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("someFunction()"))
        );

        vm.prank(operator);
        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        vault.manage(address(0), data, 0);
    }

    function test_RevertManageInvalidCalldata() public {
        bytes memory data = new bytes(3);

        vm.prank(operator);
        vm.expectRevert(LegionSafe.CallNotAuthorized.selector);
        vault.manage(address(dex), data, 0);
    }

    // ====================================
    // Integration Tests with DEX
    // ====================================

    function test_Integration_SwapTokens() public {
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        uint256 swapAmount = 500 * 10 ** 18;

        vm.prank(operator);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, address(dex), swapAmount),
            0
        );

        uint256 tokenABefore = tokenA.balanceOf(address(vault));
        uint256 tokenBBefore = tokenB.balanceOf(address(vault));

        bytes memory swapData = abi.encodeWithSelector(
            swapSelector,
            address(tokenA),
            address(tokenB),
            swapAmount,
            swapAmount
        );

        vm.prank(operator);
        vault.manage(address(dex), swapData, 0);

        assertEq(tokenA.balanceOf(address(vault)), tokenABefore - swapAmount);
        assertEq(tokenB.balanceOf(address(vault)), tokenBBefore + swapAmount);
    }

    function test_Integration_MultipleSwaps() public {
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        uint256 swapAmount = 100 * 10 ** 18;

        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), swapAmount, swapAmount), 0);
        vault.manage(address(tokenB), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenB), address(tokenA), swapAmount, swapAmount), 0);
        vm.stopPrank();

        assertApproxEqAbs(tokenA.balanceOf(address(vault)), 1000 * 10 ** 18, 1);
        assertApproxEqAbs(tokenB.balanceOf(address(vault)), 1000 * 10 ** 18, 1);
    }

    function test_Integration_CompleteWorkflow() public {
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        uint256 swapAmount = 200 * 10 ** 18;

        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), swapAmount, swapAmount), 0);
        vm.stopPrank();

        uint256 profitAmount = 100 * 10 ** 18;
        uint256 ownerBalanceBefore = tokenB.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawERC20(address(tokenB), profitAmount);

        assertEq(tokenB.balanceOf(owner), ownerBalanceBefore + profitAmount);
    }

    // ====================================
    // Whitelisted Approvals Tests
    // ====================================

    function test_SetSpenderWhitelist() public {
        address router = address(0x123);

        vm.startPrank(owner);
        vault.setSpenderWhitelist(router, true);
        vm.stopPrank();

        assertTrue(vault.whitelistedSpenders(router));
    }

    function test_RevertSetSpenderWhitelist_NotOwner() public {
        address router = address(0x123);

        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorized));
        vault.setSpenderWhitelist(router, true);
    }

    function test_RevertSetSpenderWhitelist_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        vault.setSpenderWhitelist(address(0), true);
    }

    function test_ApproveToWhitelistedSpender() public {
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.prank(owner);
        vault.setSpenderWhitelist(router, true);

        vm.prank(operator);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, router, type(uint256).max),
            0
        );

        assertEq(tokenA.allowance(address(vault), router), type(uint256).max);
    }

    function test_RevertApproveToNonWhitelistedSpender() public {
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.prank(operator);
        vm.expectRevert(LegionSafe.SpenderNotWhitelisted.selector);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, router, type(uint256).max),
            0
        );
    }

    function test_ApproveMultipleTokensToWhitelistedSpender() public {
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.prank(owner);
        vault.setSpenderWhitelist(router, true);

        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, router, 1000e18), 0);
        vault.manage(address(tokenB), abi.encodeWithSelector(approveSelector, router, 2000e18), 0);
        vm.stopPrank();

        assertEq(tokenA.allowance(address(vault), router), 1000e18);
        assertEq(tokenB.allowance(address(vault), router), 2000e18);
    }

    function test_RemoveSpenderFromWhitelist() public {
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(router, true);
        vault.setSpenderWhitelist(router, false);
        vm.stopPrank();

        vm.prank(operator);
        vm.expectRevert(LegionSafe.SpenderNotWhitelisted.selector);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, router, type(uint256).max),
            0
        );
    }

    // ====================================
    // Spending Limits Tests
    // ====================================

    function test_AddTrackedToken() public {
        vm.prank(owner);
        vault.addTrackedToken(address(tokenA));

        address[] memory tracked = vault.getTrackedTokens();
        assertEq(tracked.length, 1);
        assertEq(tracked[0], address(tokenA));
    }

    function test_RevertAddTrackedToken_AlreadyTracked() public {
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));

        vm.expectRevert(LegionSafe.TokenAlreadyTracked.selector);
        vault.addTrackedToken(address(tokenA));
        vm.stopPrank();
    }

    function test_RevertAddTrackedToken_NotOwner() public {
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorized));
        vault.addTrackedToken(address(tokenA));
    }

    function test_RemoveTrackedToken() public {
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.addTrackedToken(address(tokenB));
        vault.removeTrackedToken(address(tokenA));
        vm.stopPrank();

        address[] memory tracked = vault.getTrackedTokens();
        assertEq(tracked.length, 1);
        assertEq(tracked[0], address(tokenB));
    }

    function test_RevertRemoveTrackedToken_NotTracked() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.TokenNotTracked.selector);
        vault.removeTrackedToken(address(tokenA));
    }

    function test_SetSpendingLimit() public {
        uint256 limit = 100e18;

        vm.prank(owner);
        vault.setSpendingLimit(address(tokenA), limit);

        (uint256 limitPerWindow, , ) = vault.spendingLimits(address(tokenA));
        assertEq(limitPerWindow, limit);
    }

    function test_GetRemainingLimit() public {
        uint256 limit = 100e18;

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vm.stopPrank();

        (uint256 remaining, uint256 windowEndsAt) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit);
        assertGt(windowEndsAt, block.timestamp);
    }

    function test_SpendingWithinLimit() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 50e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );
        vm.stopPrank();

        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit - spendAmount);
    }

    function test_RevertSpendingExceedingLimit() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 150e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                LegionSafe.SpendingLimitExceeded.selector,
                address(tokenA),
                spendAmount,
                limit
            )
        );
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );
    }

    function test_SpendingLimitWindowReset() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 100e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        vm.warp(block.timestamp + 6 hours + 1);

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        assertTrue(true);
    }

    function test_MultipleTokensTrackedIndependently() public {
        uint256 limitA = 100e18;
        uint256 limitB = 200e18;
        uint256 spendAmount = 100e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.addTrackedToken(address(tokenB));
        vault.setSpendingLimit(address(tokenA), limitA);
        vault.setSpendingLimit(address(tokenB), limitB);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        vm.startPrank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );
        vm.stopPrank();

        (uint256 remainingB, ) = vault.getRemainingLimit(address(tokenB));
        assertEq(remainingB, limitB);
    }

    // ====================================
    // Balance Snapshot Tests
    // ====================================

    function test_TrackNativeTokenSpending() public {
        uint256 limit = 5 ether;
        uint256 spendAmount = 2 ether;
        bytes4 swapSelector = MockDEX.swapETHForTokens.selector;

        vm.startPrank(owner);
        vault.addTrackedToken(address(0));
        vault.setSpendingLimit(address(0), limit);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), spendAmount),
            spendAmount
        );

        (uint256 remaining, ) = vault.getRemainingLimit(address(0));
        assertEq(remaining, limit - spendAmount);
    }

    function test_BalanceIncreaseDoesNotCountAsSpending() public {
        uint256 limit = 100e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.addTrackedToken(address(tokenB));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        uint256 spendAmount = 50e18;
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        (uint256 remainingA, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remainingA, limit - spendAmount);

        (uint256 remainingB, ) = vault.getRemainingLimit(address(tokenB));
        assertEq(remainingB, 0);
    }

    function test_ApprovalDoesNotCountAsSpending() public {
        uint256 limit = 100e18;
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(router, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, router, type(uint256).max),
            0
        );

        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit);
    }

    // ====================================
    // Edge Cases Tests
    // ====================================

    function test_NoLimitConfigured() public {
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        uint256 largeAmount = 999e18;
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), largeAmount, largeAmount),
            0
        );

        assertTrue(true);
    }

    function test_EmptyTrackedTokensList() public {
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), 50e18, 50e18),
            0
        );

        assertTrue(true);
    }

    function test_FailedTransactionDoesNotUpdateSpending() public {
        uint256 limit = 100e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        uint256 impossibleAmount = 10000e18;
        vm.prank(operator);
        vm.expectRevert();
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), impossibleAmount, impossibleAmount),
            0
        );

        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit);
    }

    function test_WindowBoundaryBurstSpending() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 100e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        vm.warp(block.timestamp + 6 hours + 1);

        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        assertTrue(true);
    }

    // ====================================
    // Batch Management Tests
    // ====================================

    function test_ManageBatch_MultipleApprovals() public {
        vm.prank(owner);
        vault.setSpenderWhitelist(address(dex), true);

        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(tokenA);
        data[0] = abi.encodeWithSelector(approveSelector, address(dex), 1000e18);
        values[0] = 0;

        targets[1] = address(tokenB);
        data[1] = abi.encodeWithSelector(approveSelector, address(dex), 2000e18);
        values[1] = 0;

        vm.prank(operator);
        vault.manageBatch(targets, data, values);

        assertEq(tokenA.allowance(address(vault), address(dex)), 1000e18);
        assertEq(tokenB.allowance(address(vault), address(dex)), 2000e18);
    }

    function test_ManageBatch_ApproveAndSwap() public {
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        uint256 swapAmount = 100e18;
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(tokenA);
        data[0] = abi.encodeWithSelector(approveSelector, address(dex), swapAmount);
        values[0] = 0;

        targets[1] = address(dex);
        data[1] = abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), swapAmount, swapAmount);
        values[1] = 0;

        uint256 tokenABefore = tokenA.balanceOf(address(vault));
        uint256 tokenBBefore = tokenB.balanceOf(address(vault));

        vm.prank(operator);
        vault.manageBatch(targets, data, values);

        assertEq(tokenA.balanceOf(address(vault)), tokenABefore - swapAmount);
        assertEq(tokenB.balanceOf(address(vault)), tokenBBefore + swapAmount);
    }

    function test_ManageBatch_RespectsSpendingLimit() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 60e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(tokenA);
        data[0] = abi.encodeWithSelector(approveSelector, address(dex), spendAmount);
        values[0] = 0;

        targets[1] = address(dex);
        data[1] = abi.encodeWithSelector(
            swapSelector,
            address(tokenA),
            address(tokenB),
            spendAmount,
            spendAmount
        );
        values[1] = 0;

        vm.prank(operator);
        vault.manageBatch(targets, data, values);

        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit - spendAmount);
    }

    function test_RevertManageBatch_ExceedsSpendingLimit() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 150e18;
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);
        uint256[] memory values = new uint256[](2);

        targets[0] = address(tokenA);
        data[0] = abi.encodeWithSelector(approveSelector, address(dex), spendAmount);
        values[0] = 0;

        targets[1] = address(dex);
        data[1] = abi.encodeWithSelector(
            swapSelector,
            address(tokenA),
            address(tokenB),
            spendAmount,
            spendAmount
        );
        values[1] = 0;

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                LegionSafe.SpendingLimitExceeded.selector,
                address(tokenA),
                spendAmount,
                limit
            )
        );
        vault.manageBatch(targets, data, values);
    }

    function test_RevertManageBatch_Unauthorized() public {
        address[] memory targets = new address[](1);
        bytes[] memory data = new bytes[](1);
        uint256[] memory values = new uint256[](1);

        targets[0] = address(tokenA);
        data[0] = abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), address(dex), 1000e18);
        values[0] = 0;

        vm.prank(unauthorized);
        vm.expectRevert(LegionSafe.Unauthorized.selector);
        vault.manageBatch(targets, data, values);
    }

    function test_RevertManageBatch_MismatchedArrays() public {
        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](1);
        uint256[] memory values = new uint256[](2);

        vm.prank(operator);
        vm.expectRevert(LegionSafe.InvalidInput.selector);
        vault.manageBatch(targets, data, values);
    }
}

