#!/bin/bash
# Withdraw ETH from LegionSafe
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/withdraw-eth.sh <recipient_address> <amount_in_wei>
# Example: bash dev-scripts/withdraw-eth.sh 0x123... 1000000000000000000  # 1 ETH

set -e  # Exit on error

if [ $# -lt 2 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/withdraw-eth.sh <recipient_address> <amount_in_wei>"
    echo "Example: bash dev-scripts/withdraw-eth.sh 0x123... 1000000000000000000  # 1 ETH"
    echo ""
    echo "Tip: Use 'cast --to-wei <amount> eth' to convert ETH to wei"
    exit 1
fi

RECIPIENT=$1
AMOUNT=$2

echo "======================================"
echo "Withdrawing ETH from LegionSafe"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "Recipient: $RECIPIENT"
echo "Amount (wei): $AMOUNT"
echo "Amount (ETH): $(cast --from-wei $AMOUNT)"
echo "======================================"
echo ""

# Call withdrawETH
cast send $LEGION_SAFE_ADDRESS \
  "withdrawETH(address,uint256)" \
  $RECIPIENT \
  $AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

echo ""
echo "======================================"
echo "ETH withdrawal completed!"
echo "======================================"
