// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LegionSafe.sol";
import "./mocks/LegionSafeV2Mock.sol";
import "./mocks/MockERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title LegionSafeUpgradeTest
 * @notice Test suite for UUPS upgradeability and Ownable2Step functionality
 */
contract LegionSafeUpgradeTest is Test {
    LegionSafe public vault;
    LegionSafe public implementation;
    ERC1967Proxy public proxy;
    MockERC20 public token;

    address public owner;
    address public operator;
    address public unauthorized;

    event Upgraded(address indexed implementation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

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
        vault = LegionSafe(address(proxy));

        // Deploy test token
        token = new MockERC20("Test Token", "TEST");
        token.mint(address(vault), 1000 * 10 ** 18);
        vm.deal(address(vault), 10 ether);
    }

    // ====================================
    // Initialization Tests
    // ====================================

    function test_Initialization_Success() public view {
        assertEq(vault.owner(), owner);
        assertEq(vault.operator(), operator);
    }

    function test_RevertInitializeTwice() public {
        // Try to initialize again
        vm.expectRevert();
        vault.initialize(address(0x4), address(0x5));
    }

    function test_RevertInitializeImplementationDirectly() public {
        // Implementation should be disabled for initialization
        vm.expectRevert();
        implementation.initialize(address(0x4), address(0x5));
    }

    // ====================================
    // Upgrade Authorization Tests
    // ====================================

    function test_OnlyOwnerCanUpgrade() public {
        // Deploy new implementation
        LegionSafe newImpl = new LegionSafe();

        // Owner should be able to upgrade
        vm.prank(owner);
        vault.upgradeToAndCall(address(newImpl), "");

        // Verify upgrade worked
        assertTrue(true);
    }

    function test_RevertUpgradeUnauthorized_Operator() public {
        LegionSafe newImpl = new LegionSafe();

        vm.prank(operator);
        vm.expectRevert();
        vault.upgradeToAndCall(address(newImpl), "");
    }

    function test_RevertUpgradeUnauthorized_Stranger() public {
        LegionSafe newImpl = new LegionSafe();

        vm.prank(unauthorized);
        vm.expectRevert();
        vault.upgradeToAndCall(address(newImpl), "");
    }

    function test_RevertUpgradeToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        vault.upgradeToAndCall(address(0), "");
    }

    // ====================================
    // State Preservation Tests
    // ====================================

    function test_StatePreservedAfterUpgrade() public {
        // Set up some state
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));

        vm.prank(owner);
        vault.setCallAuthorization(address(token), selector, true);

        // Record state before upgrade
        address ownerBefore = vault.owner();
        address operatorBefore = vault.operator();
        bool authBefore = vault.authorizedCalls(address(token), selector);
        uint256 ethBalanceBefore = address(vault).balance;
        uint256 tokenBalanceBefore = token.balanceOf(address(vault));

        // Deploy and upgrade to new implementation
        LegionSafe newImpl = new LegionSafe();

        vm.prank(owner);
        vault.upgradeToAndCall(address(newImpl), "");

        // Verify state preserved
        assertEq(vault.owner(), ownerBefore, "Owner changed");
        assertEq(vault.operator(), operatorBefore, "Operator changed");
        assertTrue(vault.authorizedCalls(address(token), selector), "Authorization lost");
        assertEq(address(vault).balance, ethBalanceBefore, "ETH balance changed");
        assertEq(token.balanceOf(address(vault)), tokenBalanceBefore, "Token balance changed");
    }

    function test_FunctionalityPreservedAfterUpgrade() public {
        // Authorize a call
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));

        vm.startPrank(owner);
        vault.setCallAuthorization(address(token), selector, true);
        vm.stopPrank();

        // Upgrade
        LegionSafe newImpl = new LegionSafe();
        vm.prank(owner);
        vault.upgradeToAndCall(address(newImpl), "");

        // Test that manage still works
        bytes memory data = abi.encodeWithSelector(
            selector,
            address(0x7),
            100 * 10 ** 18
        );

        vm.prank(operator);
        vault.manage(address(token), data, 0);

        assertEq(token.balanceOf(address(0x7)), 100 * 10 ** 18);
    }

    // ====================================
    // Upgrade to V2 Tests
    // ====================================

    function test_UpgradeToV2_Success() public {
        // Deploy V2 implementation
        LegionSafeV2Mock v2Impl = new LegionSafeV2Mock();

        // Record state before upgrade
        address ownerBefore = vault.owner();
        address operatorBefore = vault.operator();

        // Upgrade to V2 and initialize V2
        bytes memory initV2Data = abi.encodeWithSelector(
            LegionSafeV2Mock.initializeV2.selector
        );

        vm.prank(owner);
        vault.upgradeToAndCall(address(v2Impl), initV2Data);

        // Cast to V2 interface
        LegionSafeV2Mock vaultV2 = LegionSafeV2Mock(address(vault));

        // Verify V2 functionality
        assertTrue(vaultV2.isV2(), "Not V2");
        assertEq(vaultV2.getVersion(), "2.0.0", "Wrong version");

        // Verify state preserved
        assertEq(vaultV2.owner(), ownerBefore, "Owner changed");
        assertEq(vaultV2.operator(), operatorBefore, "Operator changed");
    }

    function test_UpgradeToV2_StateAndFunctionalityPreserved() public {
        // Set up state in V1
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));

        vm.prank(owner);
        vault.setCallAuthorization(address(token), selector, true);

        uint256 tokenBalanceBefore = token.balanceOf(address(vault));

        // Upgrade to V2
        LegionSafeV2Mock v2Impl = new LegionSafeV2Mock();

        bytes memory initV2Data = abi.encodeWithSelector(
            LegionSafeV2Mock.initializeV2.selector
        );

        vm.prank(owner);
        vault.upgradeToAndCall(address(v2Impl), initV2Data);

        LegionSafeV2Mock vaultV2 = LegionSafeV2Mock(address(vault));

        // Verify authorization preserved
        assertTrue(vaultV2.authorizedCalls(address(token), selector));

        // Verify V1 functionality still works
        bytes memory data = abi.encodeWithSelector(
            selector,
            address(0x8),
            50 * 10 ** 18
        );

        vm.prank(operator);
        vaultV2.manage(address(token), data, 0);

        assertEq(token.balanceOf(address(0x8)), 50 * 10 ** 18);
        assertEq(token.balanceOf(address(vaultV2)), tokenBalanceBefore - 50 * 10 ** 18);

        // Verify V2 specific functionality
        assertEq(vaultV2.getVersion(), "2.0.0");
        assertTrue(vaultV2.isV2());
    }

    function test_CanUpgradeMultipleTimes() public {
        // First upgrade
        LegionSafe impl2 = new LegionSafe();
        vm.prank(owner);
        vault.upgradeToAndCall(address(impl2), "");

        // Second upgrade
        LegionSafe impl3 = new LegionSafe();
        vm.prank(owner);
        vault.upgradeToAndCall(address(impl3), "");

        // Third upgrade to V2
        LegionSafeV2Mock v2Impl = new LegionSafeV2Mock();
        bytes memory initV2Data = abi.encodeWithSelector(
            LegionSafeV2Mock.initializeV2.selector
        );

        vm.prank(owner);
        vault.upgradeToAndCall(address(v2Impl), initV2Data);

        LegionSafeV2Mock vaultV2 = LegionSafeV2Mock(address(vault));
        assertTrue(vaultV2.isV2());
    }

    // ====================================
    // Ownable2Step Additional Tests
    // ====================================

    function test_PendingOwnerView() public {
        address newOwner = address(0x4);

        // Initially no pending owner
        assertEq(vault.pendingOwner(), address(0));

        // After transfer, pending owner should be set
        vm.prank(owner);
        vault.transferOwnership(newOwner);

        assertEq(vault.pendingOwner(), newOwner);
        assertEq(vault.owner(), owner); // Owner not changed yet
    }

    function test_OnlyPendingOwnerCanAccept() public {
        address newOwner = address(0x4);

        vm.prank(owner);
        vault.transferOwnership(newOwner);

        // Wrong address tries to accept
        vm.prank(unauthorized);
        vm.expectRevert();
        vault.acceptOwnership();

        // Correct pending owner accepts
        vm.prank(newOwner);
        vault.acceptOwnership();

        assertEq(vault.owner(), newOwner);
    }

    function test_OwnershipTransferCompleteWorkflow() public {
        address newOwner = address(0x4);
        address newerOwner = address(0x5);

        // Step 1: Transfer to newOwner
        vm.prank(owner);
        vault.transferOwnership(newOwner);

        // Step 2: newOwner accepts
        vm.prank(newOwner);
        vault.acceptOwnership();

        assertEq(vault.owner(), newOwner);

        // Step 3: newOwner transfers to newerOwner
        vm.prank(newOwner);
        vault.transferOwnership(newerOwner);

        // Step 4: newerOwner accepts
        vm.prank(newerOwner);
        vault.acceptOwnership();

        assertEq(vault.owner(), newerOwner);
    }

    function test_PreviousOwnerLosesAccessAfterTransfer() public {
        address newOwner = address(0x4);

        // Transfer and accept
        vm.prank(owner);
        vault.transferOwnership(newOwner);

        vm.prank(newOwner);
        vault.acceptOwnership();

        // Old owner should not be able to call owner functions
        vm.prank(owner);
        vm.expectRevert();
        vault.setOperator(address(0x6));

        // New owner should be able to
        vm.prank(newOwner);
        vault.setOperator(address(0x6));

        assertEq(vault.operator(), address(0x6));
    }

    function test_UpgradeAfterOwnershipTransfer() public {
        address newOwner = address(0x4);

        // Transfer ownership
        vm.prank(owner);
        vault.transferOwnership(newOwner);

        vm.prank(newOwner);
        vault.acceptOwnership();

        // Old owner cannot upgrade
        LegionSafe newImpl = new LegionSafe();

        vm.prank(owner);
        vm.expectRevert();
        vault.upgradeToAndCall(address(newImpl), "");

        // New owner can upgrade
        vm.prank(newOwner);
        vault.upgradeToAndCall(address(newImpl), "");

        assertTrue(true);
    }

    // ====================================
    // Edge Cases
    // ====================================

    function test_RenounceOwnership() public {
        // Ownable2Step allows renouncing by transferring to address(0)
        vm.prank(owner);
        vault.renounceOwnership();

        assertEq(vault.owner(), address(0));

        // No one should be able to perform owner functions
        vm.expectRevert();
        vault.setOperator(address(0x6));
    }

    function test_CannotUpgradeAfterRenouncingOwnership() public {
        vm.prank(owner);
        vault.renounceOwnership();

        LegionSafe newImpl = new LegionSafe();

        vm.expectRevert();
        vault.upgradeToAndCall(address(newImpl), "");
    }

    function test_ProxyDelegatesCallsCorrectly() public {
        // Verify that calls to proxy are delegated to implementation
        // This is implicit in all other tests, but let's be explicit

        // Call a function through proxy
        vm.prank(owner);
        vault.setOperator(address(0x6));

        // Verify it worked
        assertEq(vault.operator(), address(0x6));

        // Storage should be in proxy, not implementation
        assertEq(implementation.operator(), address(0));
    }

    function test_ImplementationCannotBeUsedDirectly() public {
        // The implementation contract should have initializers disabled
        vm.expectRevert();
        implementation.initialize(address(0x4), address(0x5));

        // And should not have any state
        assertEq(implementation.owner(), address(0));
        assertEq(implementation.operator(), address(0));
    }
}
