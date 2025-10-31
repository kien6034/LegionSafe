#!/bin/bash
# Deploy LegionSafe contract
# Make sure to run: source env.sh before executing this script

set -e  # Exit on error

echo "======================================"
echo "LegionSafe Deployment"
echo "======================================"
echo "RPC URL: $RPC_URL"
echo "Owner: $OWNER_ADDRESS"
echo "Operator: $OPERATOR_ADDRESS"
echo "======================================"

# Deploy the contract
forge script script/Deploy.s.sol:DeployLegionSafe \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv

echo ""
echo "======================================"
echo "Deployment completed!"
echo "======================================"
echo "IMPORTANT: Update LEGION_SAFE_ADDRESS in env.sh with the deployed address shown above"
echo "======================================"