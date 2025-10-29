// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LegionSafe.sol";

/**
 * @title DeployLegionSafe
 * @notice Deployment script for LegionSafe contract
 * @dev Usage: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast --verify
 */
contract DeployLegionSafe is Script {
    function run() external {
        // Read environment variables for owner and operator addresses
        address owner = vm.envAddress("OWNER_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");

        require(owner != address(0), "OWNER_ADDRESS not set");
        require(operator != address(0), "OPERATOR_ADDRESS not set");

        // Get the private key for deployment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying LegionSafe...");
        console.log("Owner:", owner);
        console.log("Operator:", operator);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the LegionSafe contract
        LegionSafe vault = new LegionSafe(owner, operator);

        vm.stopBroadcast();

        console.log("LegionSafe deployed at:", address(vault));
        console.log("Deployment successful!");
    }
}

/**
 * @title DeployLegionSafeLocal
 * @notice Local deployment script for testing without environment variables
 */
contract DeployLegionSafeLocal is Script {
    function run() external {
        // Use test addresses for local deployment
        address owner = address(0x1);
        address operator = address(0x2);

        console.log("Deploying LegionSafe locally...");
        console.log("Owner:", owner);
        console.log("Operator:", operator);

        vm.startBroadcast();

        // Deploy the LegionSafe contract
        LegionSafe vault = new LegionSafe(owner, operator);

        vm.stopBroadcast();

        console.log("LegionSafe deployed at:", address(vault));
        console.log("Local deployment successful!");
    }
}
