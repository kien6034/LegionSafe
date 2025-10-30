// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/LegionSafe.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title DeployLegionSafe
 * @notice Deployment script for LegionSafe contract using UUPS proxy pattern
 * @dev Deploys both implementation and proxy, then initializes through proxy
 * Usage: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast --verify
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

        console.log("=================================================");
        console.log("Deploying LegionSafe with UUPS Proxy Pattern");
        console.log("=================================================");
        console.log("Owner:", owner);
        console.log("Operator:", operator);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy the implementation contract
        console.log("Step 1: Deploying implementation...");
        LegionSafe implementation = new LegionSafe();
        console.log("Implementation deployed at:", address(implementation));
        console.log("");

        // Step 2: Prepare initialization data
        console.log("Step 2: Preparing initialization data...");
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            operator
        );
        console.log("Initialization data prepared");
        console.log("");

        // Step 3: Deploy the proxy
        console.log("Step 3: Deploying ERC1967 proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        console.log("");

        vm.stopBroadcast();

        console.log("=================================================");
        console.log("Deployment Complete!");
        console.log("=================================================");
        console.log("IMPORTANT: Use the PROXY address for all interactions");
        console.log("Proxy Address (use this):", address(proxy));
        console.log("Implementation Address (reference only):", address(implementation));
        console.log("");
        console.log("Verifying initialization...");

        // Verify the deployment
        LegionSafe vault = LegionSafe(address(proxy));
        console.log("Owner:", vault.owner());
        console.log("Operator:", vault.operator());
        console.log("");
        console.log("Deployment successful!");
    }
}

/**
 * @title DeployLegionSafeLocal
 * @notice Local deployment script for testing without environment variables
 * @dev Uses test addresses for local/anvil deployment
 */
contract DeployLegionSafeLocal is Script {
    function run() external {
        // Use test addresses for local deployment
        address owner = address(0x1);
        address operator = address(0x2);

        console.log("=================================================");
        console.log("Deploying LegionSafe Locally (UUPS Proxy)");
        console.log("=================================================");
        console.log("Owner:", owner);
        console.log("Operator:", operator);
        console.log("");

        vm.startBroadcast();

        // Step 1: Deploy implementation
        console.log("Step 1: Deploying implementation...");
        LegionSafe implementation = new LegionSafe();
        console.log("Implementation deployed at:", address(implementation));
        console.log("");

        // Step 2: Prepare initialization data
        console.log("Step 2: Preparing initialization data...");
        bytes memory initData = abi.encodeWithSelector(
            LegionSafe.initialize.selector,
            owner,
            operator
        );
        console.log("");

        // Step 3: Deploy proxy
        console.log("Step 3: Deploying ERC1967 proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        console.log("");

        vm.stopBroadcast();

        console.log("=================================================");
        console.log("Local Deployment Complete!");
        console.log("=================================================");
        console.log("Proxy Address (use this):", address(proxy));
        console.log("Implementation Address:", address(implementation));
        console.log("");

        // Verify
        LegionSafe vault = LegionSafe(address(proxy));
        console.log("Owner:", vault.owner());
        console.log("Operator:", vault.operator());
        console.log("");
        console.log("Local deployment successful!");
    }
}

/**
 * @title UpgradeLegionSafe
 * @notice Upgrade script for existing LegionSafe proxy
 * @dev Deploys new implementation and upgrades existing proxy
 * Usage: forge script script/Deploy.s.sol:UpgradeLegionSafe --rpc-url <RPC_URL> --broadcast
 */
contract UpgradeLegionSafe is Script {
    function run() external {
        // Read environment variables
        address proxyAddress = vm.envAddress("LEGION_SAFE_ADDRESS");
        require(proxyAddress != address(0), "LEGION_SAFE_ADDRESS not set");

        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=================================================");
        console.log("Upgrading LegionSafe Implementation");
        console.log("=================================================");
        console.log("Proxy Address:", proxyAddress);
        console.log("");

        vm.startBroadcast(ownerPrivateKey);

        // Step 1: Deploy new implementation
        console.log("Step 1: Deploying new implementation...");
        LegionSafe newImplementation = new LegionSafe();
        console.log("New implementation deployed at:", address(newImplementation));
        console.log("");

        // Step 2: Upgrade the proxy
        console.log("Step 2: Upgrading proxy...");
        LegionSafe vault = LegionSafe(proxyAddress);
        vault.upgradeToAndCall(address(newImplementation), "");
        console.log("Upgrade complete!");
        console.log("");

        vm.stopBroadcast();

        console.log("=================================================");
        console.log("Upgrade Successful!");
        console.log("=================================================");
        console.log("Proxy Address (unchanged):", proxyAddress);
        console.log("New Implementation Address:", address(newImplementation));
        console.log("");
        console.log("Verifying state preservation...");
        console.log("Owner:", vault.owner());
        console.log("Operator:", vault.operator());
    }
}
