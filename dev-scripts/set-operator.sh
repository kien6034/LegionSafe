#!/bin/bash
# Change the operator address (owner only)
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/set-operator.sh <new_operator_address>
# Example: bash dev-scripts/set-operator.sh 0x123...

set -e  # Exit on error

if [ $# -lt 1 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/set-operator.sh <new_operator_address>"
    echo "Example: bash dev-scripts/set-operator.sh 0x123..."
    exit 1
fi

NEW_OPERATOR=$1

echo "======================================"
echo "Changing Operator"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "New Operator: $NEW_OPERATOR"
echo "======================================"
echo ""

# Call setOperator
cast send $LEGION_SAFE_ADDRESS \
  "setOperator(address)" \
  $NEW_OPERATOR \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

echo ""
echo "======================================"
echo "Operator changed!"
echo "======================================"
echo "IMPORTANT: Update OPERATOR_ADDRESS in env.sh if needed"
echo "======================================"
