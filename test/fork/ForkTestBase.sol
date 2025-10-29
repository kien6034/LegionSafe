// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Base contract for fork tests with helper functions
abstract contract ForkTestBase is Test {
    /// @notice Create a fork and select it
    function createAndSelectFork(string memory rpcUrl) internal returns (uint256) {
        uint256 forkId = vm.createFork(rpcUrl);
        vm.selectFork(forkId);
        return forkId;
    }

    /// @notice Deal ERC20 tokens to an address using whale
    function dealToken(
        address token,
        address to,
        uint256 amount,
        address whale
    ) internal {
        vm.prank(whale);
        IERC20(token).transfer(to, amount);
    }

    /// @notice Get token balance
    function balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    /// @notice Get ETH/BNB balance
    function balanceOfNative(address account) internal view returns (uint256) {
        return account.balance;
    }

    /// @notice Label addresses for better trace output
    function labelAddresses(
        address[] memory addresses,
        string[] memory labels
    ) internal {
        require(addresses.length == labels.length, "Length mismatch");
        for (uint256 i = 0; i < addresses.length; i++) {
            vm.label(addresses[i], labels[i]);
        }
    }
}

contract ForkTestBaseTest is ForkTestBase {
    function testForkCreation() public {
        uint256 forkId = createAndSelectFork("https://bsc-dataseed1.binance.org");
        assertEq(vm.activeFork(), forkId);
    }
}
