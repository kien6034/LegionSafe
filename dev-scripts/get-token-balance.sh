#!/bin/bash
# Get token balance of LegionSafe
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/get-token-balance.sh <token_address>
# Example: bash dev-scripts/get-token-balance.sh 0x123...

set -e  # Exit on error

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/get-token-balance.sh <token_address>"
    echo "Example: bash dev-scripts/get-token-balance.sh 0x123..."
    exit 1
fi

TOKEN=$1

echo "======================================"
echo "Token Balance Check"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "Token: $TOKEN"
echo "======================================"
echo ""

# Get token balance
echo "Balance (raw):"
cast call $LEGION_SAFE_ADDRESS \
  "getTokenBalance(address)(uint256)" \
  $TOKEN \
  --rpc-url $RPC_URL

echo ""

# Get token symbol and decimals for better display
echo "Token Symbol:"
cast call $TOKEN "symbol()(string)" --rpc-url $RPC_URL

echo ""
echo "Token Decimals:"
cast call $TOKEN "decimals()(uint8)" --rpc-url $RPC_URL

echo ""
echo "======================================"
