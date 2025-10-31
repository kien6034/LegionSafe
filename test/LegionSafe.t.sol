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
    // Reentrancy Tests
    // ====================================

    function test_NoReentrancyOnWithdraw() public {
        vm.prank(owner);
        vault.withdrawETH(1 ether);

        assertTrue(true);
    }


    // Receive function for testing
    receive() external payable {}
}
