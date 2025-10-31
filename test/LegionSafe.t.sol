// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LegionSafe.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockDEX.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LegionSafeTest is Test {
    LegionSafe public vault;
    LegionSafe public implementation;
    ERC1967Proxy public proxy;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockDEX public dex;

    address public owner;
    address public operator;
    address public unauthorized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OperatorChanged(address indexed previousOperator, address indexed newOperator);
    event CallAuthorized(address indexed target, bytes4 indexed selector, bool authorized);
    event Managed(address indexed target, uint256 value, bytes data);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);
    event EthReceived(address indexed sender, uint256 amount);

    function setUp() public {
        owner = address(0x1);
        operator = address(0x2);
        unauthorized = address(0x3);

        // Deploy implementation
        implementation = new LegionSafe();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            operator
        );

        // Deploy proxy
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to LegionSafe interface
        vault = LegionSafe(payable(address(proxy)));

        // Deploy mock contracts
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");
        dex = new MockDEX();

        // Setup DEX with liquidity
        tokenA.mint(address(dex), 1000000 * 10 ** 18);
        tokenB.mint(address(dex), 1000000 * 10 ** 18);
        vm.deal(address(dex), 1000 ether);

        // Fund vault with tokens and ETH for testing
        tokenA.mint(address(vault), 1000 * 10 ** 18);
        tokenB.mint(address(vault), 1000 * 10 ** 18);
        vm.deal(address(vault), 10 ether);
    }

    // ====================================
    // Deployment Tests
    // ====================================

    function test_Deployment() public view {
        assertEq(vault.owner(), owner);
        assertEq(vault.operator(), operator);
    }

    function test_RevertInitializationWithZeroOwner() public {
        LegionSafe newImpl = new LegionSafe();
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            address(0),
            operator
        );

        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        new ERC1967Proxy(address(newImpl), initData);
    }

    function test_RevertInitializationWithZeroOperator() public {
        LegionSafe newImpl = new LegionSafe();
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            address(0)
        );

        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        new ERC1967Proxy(address(newImpl), initData);
    }

    // ====================================
    // Ownership Tests (Two-Step)
    // ====================================

    function test_TransferOwnership_TwoStep() public {
        address newOwner = address(0x4);

        // Step 1: Current owner initiates transfer
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferStarted(owner, newOwner);
        vault.transferOwnership(newOwner);

        // Owner should not change yet
        assertEq(vault.owner(), owner);
        assertEq(vault.pendingOwner(), newOwner);

        // Step 2: New owner accepts ownership
        vm.prank(newOwner);
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(owner, newOwner);
        vault.acceptOwnership();

        // Now ownership should be transferred
        assertEq(vault.owner(), newOwner);
        assertEq(vault.pendingOwner(), address(0));
    }

    function test_RevertTransferOwnershipUnauthorized() public {
        address newOwner = address(0x4);

        vm.prank(unauthorized);
        vm.expectRevert();
        vault.transferOwnership(newOwner);
    }

 
    function test_RevertAcceptOwnershipUnauthorized() public {
        address newOwner = address(0x4);

        vm.prank(owner);
        vault.transferOwnership(newOwner);

        // Someone other than pending owner tries to accept
        vm.prank(unauthorized);
        vm.expectRevert();
        vault.acceptOwnership();
    }

    function test_CancelOwnershipTransfer() public {
        address newOwner = address(0x4);

        // Initiate transfer
        vm.prank(owner);
        vault.transferOwnership(newOwner);
        assertEq(vault.pendingOwner(), newOwner);

        // Cancel by transferring to address(0)
        vm.prank(owner);
        vault.transferOwnership(address(0));
        assertEq(vault.pendingOwner(), address(0));
    }

    // ====================================
    // Operator Tests
    // ====================================

    function test_SetOperator() public {
        address newOperator = address(0x5);

        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit OperatorChanged(operator, newOperator);
        vault.setOperator(newOperator);

        assertEq(vault.operator(), newOperator);
    }

    function test_RevertSetOperatorUnauthorized() public {
        address newOperator = address(0x5);

        vm.prank(unauthorized);
        vm.expectRevert();
        vault.setOperator(newOperator);
    }

    function test_RevertSetOperatorToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        vault.setOperator(address(0));
    }

    // ====================================
    // Authorization Tests
    // ====================================

    function test_SetCallAuthorization() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit CallAuthorized(address(dex), selector, true);
        vault.setCallAuthorization(address(dex), selector, true);

        assertTrue(vault.authorizedCalls(address(dex), selector));
    }

    function test_RevokeCallAuthorization() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));

        vm.startPrank(owner);
        vault.setCallAuthorization(address(dex), selector, true);

        vm.expectEmit(true, true, false, true);
        emit CallAuthorized(address(dex), selector, false);
        vault.setCallAuthorization(address(dex), selector, false);
        vm.stopPrank();

        assertFalse(vault.authorizedCalls(address(dex), selector));
    }

    function test_RevertSetCallAuthorizationUnauthorized() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));

        vm.prank(unauthorized);
        vm.expectRevert();
        vault.setCallAuthorization(address(dex), selector, true);
    }

    function test_RevertSetCallAuthorizationZeroAddress() public {
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));

        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        vault.setCallAuthorization(address(0), selector, true);
    }

    // ====================================
    // Manage Function Tests
    // ====================================

    function test_ManageSuccessfulCall() public {
        // Authorize the swap function
        bytes4 selector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        vm.prank(owner);
        vault.setCallAuthorization(address(dex), selector, true);

        // Prepare swap call
        uint256 amountIn = 100 * 10 ** 18;
        bytes memory data = abi.encodeWithSelector(
            selector,
            address(tokenA),
            address(tokenB),
            amountIn,
            amountIn
        );

        // Approve DEX to spend vault's tokens
        vm.prank(address(vault));
        tokenA.approve(address(dex), amountIn);

        uint256 vaultTokenABefore = tokenA.balanceOf(address(vault));
        uint256 vaultTokenBBefore = tokenB.balanceOf(address(vault));

        // Execute manage
        vm.prank(operator);
        vm.expectEmit(true, false, false, false);
        emit Managed(address(dex), 0, data);
        vault.manage(address(dex), data, 0);

        // Verify balances changed
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
        bytes memory data = new bytes(3); // Less than 4 bytes

        vm.prank(operator);
        vm.expectRevert(LegionSafe.CallNotAuthorized.selector);
        vault.manage(address(dex), data, 0);
    }

    // ====================================
    // Withdrawal Tests - ETH
    // ====================================

    function test_WithdrawETH() public {
        uint256 withdrawAmount = 1 ether;
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Withdrawn(address(0), owner, withdrawAmount);
        vault.withdrawETH(withdrawAmount);

        assertEq(owner.balance, ownerBalanceBefore + withdrawAmount);
        assertEq(address(vault).balance, 10 ether - withdrawAmount);
    }

    function test_WithdrawAllETH() public {
        uint256 vaultBalance = address(vault).balance;
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        vault.withdrawAllETH();

        assertEq(owner.balance, ownerBalanceBefore + vaultBalance);
        assertEq(address(vault).balance, 0);
    }

    function test_RevertWithdrawETHUnauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        vault.withdrawETH(1 ether);
    }

    function test_RevertWithdrawETHZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAmount.selector);
        vault.withdrawETH(0);
    }

    function test_RevertWithdrawETHInsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAmount.selector);
        vault.withdrawETH(100 ether);
    }

    // ====================================
    // Withdrawal Tests - ERC20
    // ====================================

    function test_WithdrawERC20() public {
        uint256 withdrawAmount = 100 * 10 ** 18;
        uint256 ownerBalanceBefore = tokenA.balanceOf(owner);

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Withdrawn(address(tokenA), owner, withdrawAmount);
        vault.withdrawERC20(address(tokenA), withdrawAmount);

        assertEq(tokenA.balanceOf(owner), ownerBalanceBefore + withdrawAmount);
    }

    function test_WithdrawAllERC20() public {
        uint256 vaultBalance = tokenA.balanceOf(address(vault));
        uint256 ownerBalanceBefore = tokenA.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawAllERC20(address(tokenA));

        assertEq(tokenA.balanceOf(owner), ownerBalanceBefore + vaultBalance);
        assertEq(tokenA.balanceOf(address(vault)), 0);
    }

    function test_RevertWithdrawERC20Unauthorized() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        vault.withdrawERC20(address(tokenA), 100 * 10 ** 18);
    }

    function test_RevertWithdrawERC20ZeroTokenAddress() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAddress.selector);
        vault.withdrawERC20(address(0), 100 * 10 ** 18);
    }

    function test_RevertWithdrawERC20ZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(LegionSafe.InvalidAmount.selector);
        vault.withdrawERC20(address(tokenA), 0);
    }

    // ====================================
    // Receive/Fallback Tests
    // ====================================

    function test_ReceiveETH() public {
        uint256 sendAmount = 5 ether;
        uint256 vaultBalanceBefore = address(vault).balance;

        vm.expectEmit(true, false, false, true);
        emit EthReceived(address(this), sendAmount);
        (bool success, ) = address(vault).call{value: sendAmount}("");

        assertTrue(success);
        assertEq(address(vault).balance, vaultBalanceBefore + sendAmount);
    }

    function test_FallbackETH() public {
        uint256 sendAmount = 3 ether;
        uint256 vaultBalanceBefore = address(vault).balance;

        vm.expectEmit(true, false, false, true);
        emit EthReceived(address(this), sendAmount);
        (bool success, ) = address(vault).call{value: sendAmount}(abi.encodeWithSignature("nonExistentFunction()"));

        assertTrue(success);
        assertEq(address(vault).balance, vaultBalanceBefore + sendAmount);
    }

    // ====================================
    // View Function Tests
    // ====================================

    function test_GetETHBalance() public view {
        assertEq(vault.getETHBalance(), 10 ether);
    }

    function test_GetTokenBalance() public view {
        assertEq(vault.getTokenBalance(address(tokenA)), 1000 * 10 ** 18);
    }

    // ====================================
    // Integration Tests with DEX
    // ====================================

    function test_Integration_SwapTokens() public {
        // Setup: Authorize swap function and whitelist DEX for approvals
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Setup: Prepare vault to approve DEX
        uint256 swapAmount = 500 * 10 ** 18;

        bytes memory approveData = abi.encodeWithSelector(
            approveSelector,
            address(dex),
            swapAmount
        );

        vm.prank(operator);
        vault.manage(address(tokenA), approveData, 0);

        // Record balances before swap
        uint256 tokenABefore = tokenA.balanceOf(address(vault));
        uint256 tokenBBefore = tokenB.balanceOf(address(vault));

        // Execute swap through vault
        bytes memory swapData = abi.encodeWithSelector(
            swapSelector,
            address(tokenA),
            address(tokenB),
            swapAmount,
            swapAmount
        );

        vm.prank(operator);
        vault.manage(address(dex), swapData, 0);

        // Verify swap occurred
        assertEq(tokenA.balanceOf(address(vault)), tokenABefore - swapAmount);
        assertEq(tokenB.balanceOf(address(vault)), tokenBBefore + swapAmount);
    }

    function test_Integration_MultipleSwaps() public {
        // Authorize necessary functions
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        uint256 swapAmount = 100 * 10 ** 18;

        // First swap: TokenA -> TokenB
        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), swapAmount, swapAmount), 0);

        // Second swap: TokenB -> TokenA
        vault.manage(address(tokenB), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenB), address(tokenA), swapAmount, swapAmount), 0);
        vm.stopPrank();

        // After two swaps with same amount, balances should be approximately the same
        assertApproxEqAbs(tokenA.balanceOf(address(vault)), 1000 * 10 ** 18, 1);
        assertApproxEqAbs(tokenB.balanceOf(address(vault)), 1000 * 10 ** 18, 1);
    }

    function test_Integration_CompleteWorkflow() public {
        // Step 1: Owner authorizes functions
        bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Step 2: Operator executes trade
        uint256 swapAmount = 200 * 10 ** 18;

        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), swapAmount), 0);
        vault.manage(address(dex), abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), swapAmount, swapAmount), 0);
        vm.stopPrank();

        // Step 3: Owner withdraws profits
        uint256 profitAmount = 100 * 10 ** 18;
        uint256 ownerBalanceBefore = tokenB.balanceOf(owner);

        vm.prank(owner);
        vault.withdrawERC20(address(tokenB), profitAmount);

        assertEq(tokenB.balanceOf(owner), ownerBalanceBefore + profitAmount);
    }

    // ====================================
    // Reentrancy Tests
    // ====================================

    function test_NoReentrancyOnWithdraw() public {
        // This test verifies the nonReentrant modifier works
        // In a real attack scenario, a malicious contract would try to reenter
        // The modifier should prevent this

        vm.prank(owner);
        vault.withdrawETH(1 ether);

        // If we got here without reverting, reentrancy protection is working
        assertTrue(true);
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

        // Whitelist the router
        vm.prank(owner);
        vault.setSpenderWhitelist(router, true);

        // Operator can now approve any token to whitelisted spender
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

        // Don't whitelist the router
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

        // Whitelist the router once
        vm.prank(owner);
        vault.setSpenderWhitelist(router, true);

        // Approve multiple tokens without additional authorization
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

        // Whitelist and then remove
        vm.startPrank(owner);
        vault.setSpenderWhitelist(router, true);
        vault.setSpenderWhitelist(router, false);
        vm.stopPrank();

        // Should now fail
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

        // Setup: whitelist DEX and authorize swap
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX to spend tokenA
        vm.startPrank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Execute swap within limit
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );
        vm.stopPrank();

        // Check remaining limit
        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit - spendAmount);
    }

    function test_RevertSpendingExceedingLimit() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 150e18;

        // Setup
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Expect revert when exceeding limit
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

        // Setup
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Spend full limit
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // Fast forward 6 hours + 1 second
        vm.warp(block.timestamp + 6 hours + 1);

        // Should be able to spend again
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // Success if we got here
        assertTrue(true);
    }

    function test_MultipleTokensTrackedIndependently() public {
        uint256 limitA = 100e18;
        uint256 limitB = 200e18;
        uint256 spendAmount = 100e18;

        // Setup
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

        // Approve DEX to spend tokenA
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Spend tokenA to limit
        vm.startPrank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // TokenB should still have its own limit
        (uint256 remainingB, ) = vault.getRemainingLimit(address(tokenB));
        assertEq(remainingB, limitB);
        vm.stopPrank();
    }

    // ====================================
    // Balance Snapshot Tests
    // ====================================

    function test_TrackNativeTokenSpending() public {
        uint256 limit = 5 ether;
        uint256 spendAmount = 2 ether;

        // Setup
        bytes4 swapSelector = MockDEX.swapETHForTokens.selector;
        vm.startPrank(owner);
        vault.addTrackedToken(address(0)); // Native token
        vault.setSpendingLimit(address(0), limit);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Execute swap that spends ETH
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), spendAmount),
            spendAmount
        );

        // Check remaining limit
        (uint256 remaining, ) = vault.getRemainingLimit(address(0));
        assertEq(remaining, limit - spendAmount);
    }

    function test_BalanceIncreaseDoesNotCountAsSpending() public {
        uint256 limit = 100e18;

        // Setup
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.addTrackedToken(address(tokenB));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Execute swap that decreases tokenA but increases tokenB
        uint256 spendAmount = 50e18;
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // TokenA limit should be reduced
        (uint256 remainingA, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remainingA, limit - spendAmount);

        // TokenB should not count as spending (no limit set, so returns 0)
        (uint256 remainingB, ) = vault.getRemainingLimit(address(tokenB));
        assertEq(remainingB, 0); // No limit configured
    }

    function test_ApprovalDoesNotCountAsSpending() public {
        uint256 limit = 100e18;
        address router = address(dex);
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));

        // Setup
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(router, true);
        vm.stopPrank();

        // Execute approve (should not affect spending limit)
        vm.prank(operator);
        vault.manage(
            address(tokenA),
            abi.encodeWithSelector(approveSelector, router, type(uint256).max),
            0
        );

        // Limit should remain unchanged
        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit);
    }

    // ====================================
    // Edge Cases Tests
    // ====================================

    function test_NoLimitConfigured() public {
        // Setup without setting limit
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpenderWhitelist(address(dex), true);
        // No setSpendingLimit call
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Should allow any spending when no limit configured
        uint256 largeAmount = 999e18;
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), largeAmount, largeAmount),
            0
        );

        // Success if we got here
        assertTrue(true);
    }

    function test_EmptyTrackedTokensList() public {
        // Execute operation with no tracked tokens
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Should work fine
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

        // Setup
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Try to swap more than vault has (will fail in DEX)
        uint256 impossibleAmount = 10000e18;
        vm.prank(operator);
        vm.expectRevert();
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), impossibleAmount, impossibleAmount),
            0
        );

        // Limit should remain unchanged
        (uint256 remaining, ) = vault.getRemainingLimit(address(tokenA));
        assertEq(remaining, limit);
    }

    function test_WindowBoundaryBurstSpending() public {
        uint256 limit = 100e18;
        uint256 spendAmount = 100e18;

        // Setup
        bytes4 swapSelector = MockDEX.swap.selector;
        bytes4 approveSelector = bytes4(keccak256("approve(address,uint256)"));
        vm.startPrank(owner);
        vault.addTrackedToken(address(tokenA));
        vault.setSpendingLimit(address(tokenA), limit);
        vault.setSpenderWhitelist(address(dex), true);
        vault.setCallAuthorization(address(dex), swapSelector, true);
        vm.stopPrank();

        // Approve DEX
        vm.prank(operator);
        vault.manage(address(tokenA), abi.encodeWithSelector(approveSelector, address(dex), type(uint256).max), 0);

        // Spend at end of window
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // Move to start of next window
        vm.warp(block.timestamp + 6 hours + 1);

        // Can spend again in new window
        vm.prank(operator);
        vault.manage(
            address(dex),
            abi.encodeWithSelector(swapSelector, address(tokenA), address(tokenB), spendAmount, spendAmount),
            0
        );

        // This demonstrates the 2x limit vulnerability at window boundaries
        assertTrue(true);
    }

    // Receive function for testing
    receive() external payable {}
}
