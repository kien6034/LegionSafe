#!/bin/bash
# Authorize a function call on a target contract
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/authorize-function.sh <target_address> <function_signature> <true|false>
# Example: bash dev-scripts/authorize-function.sh 0x123... "swap(address,address,uint256,uint256)" true

set -e  # Exit on error

if [ $# -lt 3 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/authorize-function.sh <target_address> <function_signature> <true|false>"
    echo "Example: bash dev-scripts/authorize-function.sh 0x123... 'swap(address,address,uint256,uint256)' true"
    exit 1
fi

TARGET_ADDRESS=$1
FUNCTION_SIG=$2
AUTHORIZED=$3

# Calculate function selector
SELECTOR=$(cast sig "$FUNCTION_SIG")

echo "======================================"
echo "Authorizing Function Call"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "Target: $TARGET_ADDRESS"
echo "Function: $FUNCTION_SIG"
echo "Selector: $SELECTOR"
echo "Authorized: $AUTHORIZED"
echo "======================================"
echo ""

# Call setCallAuthorization
cast send $LEGION_SAFE_ADDRESS \
  "setCallAuthorization(address,bytes4,bool)" \
  $TARGET_ADDRESS \
  $SELECTOR \
  $AUTHORIZED \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

echo ""
echo "======================================"
echo "Authorization updated!"
echo "======================================"
