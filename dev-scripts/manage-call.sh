#!/bin/bash
# Execute a managed call through LegionSafe (operator only)
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/manage-call.sh <target_address> <calldata> <value>
# Example: bash dev-scripts/manage-call.sh 0x123... 0x095ea7b3... 0

set -e  # Exit on error

if [ $# -lt 3 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/manage-call.sh <target_address> <calldata> <value>"
    echo "Example: bash dev-scripts/manage-call.sh 0x123... 0x095ea7b3... 0"
    echo ""
    echo "Tip: Use 'cast calldata \"functionSig(args)\" arg1 arg2...' to generate calldata"
    exit 1
fi

TARGET=$1
CALLDATA=$2
VALUE=$3

echo "======================================"
echo "Executing Managed Call"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "Target: $TARGET"
echo "Calldata: $CALLDATA"
echo "Value: $VALUE"
echo "======================================"
echo ""

# Call manage
cast send $LEGION_SAFE_ADDRESS \
  "manage(address,bytes,uint256)" \
  $TARGET \
  $CALLDATA \
  $VALUE \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

echo ""
echo "======================================"
echo "Managed call executed!"
echo "======================================"
