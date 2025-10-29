#!/bin/bash
# Withdraw ERC20 tokens from LegionSafe
# Make sure to run: source env.sh before executing this script
#
# Usage: bash dev-scripts/withdraw-erc20.sh <token_address> <recipient_address> <amount>
# Example: bash dev-scripts/withdraw-erc20.sh 0xabc... 0x123... 1000000000000000000

set -e  # Exit on error

if [ $# -lt 3 ]; then
    echo "Error: Missing arguments"
    echo "Usage: bash dev-scripts/withdraw-erc20.sh <token_address> <recipient_address> <amount>"
    echo "Example: bash dev-scripts/withdraw-erc20.sh 0xabc... 0x123... 1000000000000000000"
    exit 1
fi

TOKEN=$1
RECIPIENT=$2
AMOUNT=$3

echo "======================================"
echo "Withdrawing ERC20 from LegionSafe"
echo "======================================"
echo "Contract: $LEGION_SAFE_ADDRESS"
echo "Token: $TOKEN"
echo "Recipient: $RECIPIENT"
echo "Amount: $AMOUNT"
echo "======================================"
echo ""

# Call withdrawERC20
cast send $LEGION_SAFE_ADDRESS \
  "withdrawERC20(address,address,uint256)" \
  $TOKEN \
  $RECIPIENT \
  $AMOUNT \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

echo ""
echo "======================================"
echo "ERC20 withdrawal completed!"
echo "======================================"
