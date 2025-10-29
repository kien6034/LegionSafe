#!/bin/bash
# Check LegionSafe contract status
# Make sure to run: source env.sh before executing this script

set -e  # Exit on error

echo "======================================"
echo "LegionSafe Status Check"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "RPC URL: $RPC_URL"
echo "======================================"
echo ""

# Get owner
echo "Owner:"
cast call $LEGION_SAFE_ADDRESS "owner()(address)" --rpc-url $RPC_URL
echo ""

# Get operator
echo "Operator:"
cast call $LEGION_SAFE_ADDRESS "operator()(address)" --rpc-url $RPC_URL
echo ""

# Get ETH balance
echo "ETH Balance:"
cast call $LEGION_SAFE_ADDRESS "getETHBalance()(uint256)" --rpc-url $RPC_URL
echo ""

# Get contract ETH balance directly
echo "Contract ETH Balance (direct):"
cast balance $LEGION_SAFE_ADDRESS --rpc-url $RPC_URL
echo ""

echo "======================================"
echo "Status check completed!"
echo "======================================"
