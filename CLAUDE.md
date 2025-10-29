# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LegionSafe is a Solidity smart contract that acts as a secure vault for managing crypto meme trading automation. The contract implements role-based access control:
- **Operator**: Can trigger arbitrary payloads (buy/sell transactions) through a `manage()` function
- **Owner**: Has exclusive rights to withdraw funds from the contract

The design is inspired by yo.xyz's vault management pattern with authorization checks.

## Development Framework

This project uses **Foundry** for Solidity development.

### Environment Setup

The project uses a standardized environment variable pattern:

1. **env.sh**: Contains environment variables for deployment and interaction
   - `PRIVATE_KEY`: Deployer's private key
   - `RPC_URL`: RPC endpoint URL (e.g., Base Sepolia, Ethereum mainnet)
   - `LEGION_SAFE_ADDRESS`: Deployed contract address

2. **dev-scripts/**: Directory containing bash scripts for common operations

### Deployment and Interaction Workflow

```bash
# 1. Create your environment file from the example
cp env.sh.example env.sh

# 2. Configure environment variables
# Edit env.sh with your private key, RPC URL, and other settings
nano env.sh

# 3. Source the environment file
source env.sh

# 4. Run deployment or interaction scripts
bash dev-scripts/deploy.sh       # Deploy the contract
bash dev-scripts/<script>.sh     # Run other interaction scripts
```

**Important**:
- `env.sh` is in `.gitignore` to prevent committing credentials
- Use `env.sh.example` as a template
- Never commit `env.sh` with real credentials

### Common Development Commands

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run all tests
forge test

# Run tests with verbosity (show trace)
forge test -vvv

# Run specific test
forge test --match-test testFunctionName

# Run tests in specific file
forge test --match-path test/ContractName.t.sol

# Check gas costs
forge test --gas-report

# Run coverage
forge coverage

# Format code
forge fmt
```

## Architecture

### Core Contract: LegionSafe

The main contract should implement:

1. **Authorization System**: Role-based access control distinguishing between operator and owner
2. **Manage Function**: Allows operators to execute arbitrary calls to external contracts (e.g., DEX routers for swaps) with authorization checks on target addresses and function signatures
3. **Withdrawal Function**: Owner-only function to extract funds from the vault
4. **Receive/Fallback**: Handle incoming ETH transfers

### Key Security Considerations

- Authorization must validate both the caller (msg.sender) and the target function signature before executing arbitrary calls
- The `manage()` function should accept: target address, calldata, and value for native token transfers
- Consider implementing allowlist/blocklist patterns for target contracts
- Owner withdrawal should support both ETH and ERC20 tokens

## Testing Strategy

Tests should be written in Solidity using Foundry's testing framework (Forge Standard Library):
- Place test files in `test/` directory with `.t.sol` extension
- Use `forge-std/Test.sol` for assertions and utilities
- Test authorization boundaries (operator vs owner privileges)
- Test edge cases for the `manage()` function (invalid targets, unauthorized callers)
- Include integration tests with mock DEX contracts
- Test reentrancy protection if handling ETH

## Project Structure

```
├── src/
│   └── LegionSafe.sol          # Main vault contract
├── test/
│   ├── LegionSafe.t.sol        # Unit tests
│   └── mocks/                  # Mock contracts for testing
│       ├── MockERC20.sol       # Mock ERC20 token
│       └── MockDEX.sol         # Mock DEX for integration tests
├── script/
│   └── Deploy.s.sol            # Foundry deployment script
├── dev-scripts/                # Bash scripts for deployment and interaction
│   └── deploy.sh               # Deploy contract script
├── lib/                        # Foundry dependencies
├── foundry.toml                # Foundry configuration
├── env.sh.example              # Example environment variables template
└── env.sh                      # Environment variables (DO NOT COMMIT - in .gitignore)
```

## Working with Dev Scripts

### Creating New Scripts

When creating new interaction scripts in `dev-scripts/`, follow this pattern:

```bash
#!/bin/bash
# dev-scripts/example-interaction.sh

# Environment variables are already loaded via: source env.sh
# Available variables: $PRIVATE_KEY, $RPC_URL, $LEGION_SAFE_ADDRESS

# Example: Call a contract function using cast
cast send $LEGION_SAFE_ADDRESS \
  "functionName(address,uint256)" \
  0xTargetAddress 1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Example: Read contract state
cast call $LEGION_SAFE_ADDRESS \
  "owner()(address)" \
  --rpc-url $RPC_URL
```

### Script Usage Pattern

Always use this workflow:
```bash
# 1. Source environment
source env.sh

# 2. Run script
bash dev-scripts/<script-name>.sh
```

### Available Scripts

The `dev-scripts/` directory contains ready-to-use bash scripts for common operations:

**Deployment & Status:**
- `deploy.sh` - Deploy the LegionSafe contract
- `check-status.sh` - Check contract status (owner, operator, balances)
- `get-token-balance.sh` - Get ERC20 token balance

**Owner Functions:**
- `authorize-function.sh` - Authorize/revoke function calls
- `withdraw-eth.sh` - Withdraw ETH from the vault
- `withdraw-erc20.sh` - Withdraw ERC20 tokens from the vault
- `set-operator.sh` - Change the operator address

**Operator Functions:**
- `manage-call.sh` - Execute authorized calls through the vault

For detailed documentation and usage examples, see [dev-scripts/README.md](dev-scripts/README.md).

### Quick Examples

**Deploy Contract:**
```bash
source env.sh
bash dev-scripts/deploy.sh
```

**Authorize a Function:**
```bash
source env.sh
bash dev-scripts/authorize-function.sh 0xDEX_ADDRESS "swap(address,address,uint256,uint256)" true
```

**Execute a Managed Call:**
```bash
source env.sh
CALLDATA=$(cast calldata "approve(address,uint256)" 0xSPENDER 1000000000000000000)
bash dev-scripts/manage-call.sh 0xTOKEN_ADDRESS $CALLDATA 0
```

**Withdraw Funds:**
```bash
source env.sh
bash dev-scripts/withdraw-eth.sh 0xRECIPIENT_ADDRESS $(cast --to-wei 1 eth)
```
