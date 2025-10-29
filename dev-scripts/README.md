# Dev Scripts

This directory contains bash scripts for deploying and interacting with the LegionSafe contract.

## Prerequisites

Before running any script:

1. Create and configure your environment file:
   ```bash
   cp ../env.sh.example ../env.sh
   nano ../env.sh  # Add your credentials
   ```

2. Source the environment file:
   ```bash
   source ../env.sh
   ```

## Scripts Overview

### Deployment

#### `deploy.sh`
Deploy the LegionSafe contract to the network specified in `env.sh`.

```bash
source ../env.sh
bash deploy.sh
```

After deployment, update `LEGION_SAFE_ADDRESS` in `env.sh` with the deployed address.

---

### Status & Information

#### `check-status.sh`
Check the current status of the LegionSafe contract including owner, operator, and ETH balance.

```bash
source ../env.sh
bash check-status.sh
```

#### `get-token-balance.sh`
Get the balance of a specific ERC20 token held by the vault.

```bash
source ../env.sh
bash get-token-balance.sh <token_address>
```

Example:
```bash
bash get-token-balance.sh 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  # USDC on Base
```

---

### Owner Functions

These scripts require the private key to belong to the contract owner.

#### `authorize-function.sh`
Authorize or revoke authorization for a specific function on a target contract.

```bash
source ../env.sh
bash authorize-function.sh <target_address> <function_signature> <true|false>
```

Examples:
```bash
# Authorize a swap function on a DEX
bash authorize-function.sh 0xDEX_ADDRESS "swap(address,address,uint256,uint256)" true

# Authorize ERC20 approve
bash authorize-function.sh 0xTOKEN_ADDRESS "approve(address,uint256)" true

# Revoke authorization
bash authorize-function.sh 0xDEX_ADDRESS "swap(address,address,uint256,uint256)" false
```

#### `withdraw-eth.sh`
Withdraw ETH from the vault to a recipient address.

```bash
source ../env.sh
bash withdraw-eth.sh <recipient_address> <amount_in_wei>
```

Examples:
```bash
# Withdraw 1 ETH
bash withdraw-eth.sh 0xRECIPIENT_ADDRESS 1000000000000000000

# Withdraw 0.1 ETH
bash withdraw-eth.sh 0xRECIPIENT_ADDRESS 100000000000000000

# Use cast to convert
bash withdraw-eth.sh 0xRECIPIENT_ADDRESS $(cast --to-wei 1 eth)
```

#### `withdraw-erc20.sh`
Withdraw ERC20 tokens from the vault to a recipient address.

```bash
source ../env.sh
bash withdraw-erc20.sh <token_address> <recipient_address> <amount>
```

Example:
```bash
# Withdraw 100 USDC (6 decimals)
bash withdraw-erc20.sh 0xTOKEN_ADDRESS 0xRECIPIENT_ADDRESS 100000000
```

#### `set-operator.sh`
Change the operator address (owner only).

```bash
source ../env.sh
bash set-operator.sh <new_operator_address>
```

Example:
```bash
bash set-operator.sh 0xNEW_OPERATOR_ADDRESS
```

---

### Operator Functions

These scripts require the private key to belong to the contract operator.

#### `manage-call.sh`
Execute an authorized call through the vault's `manage()` function.

```bash
source ../env.sh
bash manage-call.sh <target_address> <calldata> <value>
```

Examples:
```bash
# Approve a token spend
CALLDATA=$(cast calldata "approve(address,uint256)" 0xSPENDER_ADDRESS 1000000000000000000)
bash manage-call.sh 0xTOKEN_ADDRESS $CALLDATA 0

# Execute a swap on a DEX
CALLDATA=$(cast calldata "swap(address,address,uint256,uint256)" 0xTOKEN_IN 0xTOKEN_OUT 1000000 1000000)
bash manage-call.sh 0xDEX_ADDRESS $CALLDATA 0

# Send ETH with a call
bash manage-call.sh 0xTARGET_ADDRESS 0x 1000000000000000000  # Send 1 ETH
```

---

## Workflow Examples

### Complete Deployment and Setup

```bash
# 1. Setup environment
source ../env.sh

# 2. Deploy contract
bash deploy.sh
# Copy the deployed address and update env.sh

# 3. Verify deployment
bash check-status.sh

# 4. Authorize a DEX swap function (owner)
bash authorize-function.sh 0xDEX_ADDRESS "swap(address,address,uint256,uint256)" true

# 5. Authorize token approvals (owner)
bash authorize-function.sh 0xTOKEN_ADDRESS "approve(address,uint256)" true
```

### Execute a Trade

```bash
# 1. Source environment
source ../env.sh

# 2. Approve DEX to spend tokens (operator)
APPROVE_DATA=$(cast calldata "approve(address,uint256)" 0xDEX_ADDRESS 1000000000000000000)
bash manage-call.sh 0xTOKEN_ADDRESS $APPROVE_DATA 0

# 3. Execute swap (operator)
SWAP_DATA=$(cast calldata "swap(address,address,uint256,uint256)" 0xTOKEN_IN 0xTOKEN_OUT 1000000 900000)
bash manage-call.sh 0xDEX_ADDRESS $SWAP_DATA 0

# 4. Check token balance
bash get-token-balance.sh 0xTOKEN_OUT
```

### Withdraw Profits

```bash
# 1. Source environment
source ../env.sh

# 2. Check balances
bash check-status.sh
bash get-token-balance.sh 0xTOKEN_ADDRESS

# 3. Withdraw (owner only)
bash withdraw-erc20.sh 0xTOKEN_ADDRESS 0xRECIPIENT_ADDRESS 1000000
```

---

## Tips

### Generate Calldata

Use `cast calldata` to generate function calldata:

```bash
# Simple function call
cast calldata "transfer(address,uint256)" 0xRECIPIENT 1000000

# Complex function call
cast calldata "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" \
  1000000 \
  900000 \
  "[0xTOKEN_A,0xTOKEN_B]" \
  0xRECIPIENT \
  1735689600
```

### Calculate Function Selector

Use `cast sig` to get function selectors:

```bash
cast sig "swap(address,address,uint256,uint256)"
# Output: 0x12345678
```

### Convert Wei/ETH

```bash
# Convert ETH to Wei
cast --to-wei 1 eth
# Output: 1000000000000000000

# Convert Wei to ETH
cast --from-wei 1000000000000000000
# Output: 1.000000000000000000
```

### Check Transaction Status

```bash
# Get transaction receipt
cast receipt <tx_hash> --rpc-url $RPC_URL

# Get transaction details
cast tx <tx_hash> --rpc-url $RPC_URL
```

---

## Security Notes

1. **Never commit `env.sh`** - It contains your private key
2. **Owner vs Operator** - Make sure you're using the correct role's private key
3. **Test first** - Always test on testnet before mainnet
4. **Verify addresses** - Double-check all addresses before executing
5. **Check authorization** - Ensure functions are authorized before calling manage()

---

## Troubleshooting

### "Unauthorized" Error
- Check if you're using the correct private key (owner vs operator)
- Verify the function is authorized with the correct selector

### "CallNotAuthorized" Error
- The target function hasn't been authorized yet
- Use `authorize-function.sh` to authorize it first

### "InvalidAmount" Error
- Check the vault has sufficient balance
- Verify the amount is greater than zero

### Script Permissions
If you get "Permission denied":
```bash
chmod +x *.sh
```
