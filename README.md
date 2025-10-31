# LegionSafe

![LegionSafe](images/legionsafe.png)

A secure, upgradeable vault smart contract for managing crypto meme trading automation with role-based access control.

- Only owner can withdraw funds and authorize upgrades
- Only owner can authorize functions on target contracts
- Operator can execute authorized trades through `manage()` and `manageBatch()` functions
- Operator can execute arbitrary calls to authorized contracts
- Built-in spending limits with time-windowed tracking
- Whitelist system for token approvals
- UUPS upgradeable architecture

## Quick Links

- 📦 **[TypeScript SDK](sdk/README.md)** - Recommended way to interact with LegionSafe
- 🔧 **[Dev Scripts](dev-scripts/README.md)** - Bash scripts for deployment and interaction
- 📖 **[API Reference](sdk/docs/API.md)** - Complete API documentation
- 💡 **[Examples](sdk/examples/)** - Working code examples

## Getting Started

**Quick Start Guide:**

1. **Deploy**: Use the [deploy script](dev-scripts/README.md#deployment) to deploy LegionSafe with UUPS proxy
2. **Setup SDK**: Install the [TypeScript SDK](sdk/README.md) for easy interaction
3. **Configure**: Set up authorization, spending limits, and whitelists
4. **Execute**: Run automated trading strategies through the operator
5. **Withdraw**: Owner withdraws profits securely

See the [Example Usage](#example-usage) section for code examples.

## Overview

LegionSafe is an upgradeable Solidity smart contract that provides:

- **UUPS Upgradeability**: Upgradeable contract pattern for adding new features
- **Role-Based Access Control**: Distinct roles for Owner and Operator
- **Two-Step Ownership**: Enhanced security with two-step ownership transfer
- **Operator Management**: Operators can execute authorized trades through `manage()` and `manageBatch()` functions
- **Owner Withdrawals**: Owners have exclusive rights to withdraw funds (ETH and ERC20 tokens)
- **Authorization System**: Function-level authorization for target contracts
- **Spending Limits**: Time-windowed spending limits to protect against excessive trading
- **Spender Whitelist**: Whitelist system for safe token approval operations
- **Reentrancy Protection**: Built-in protection against reentrancy attacks

## Architecture

### Proxy Pattern (UUPS)

LegionSafe uses the UUPS (Universal Upgradeable Proxy Standard) pattern:

- **Proxy Contract**: Holds the state and delegates calls to implementation
- **Implementation Contract**: Contains the logic, can be upgraded
- **Owner Authorization**: Only the owner can authorize upgrades
- **State Preservation**: Contract state is preserved across upgrades

### Roles

1. **Owner**: Can withdraw funds, authorize function calls, manage upgrades, change operators, set spending limits, and whitelist spenders
2. **Operator**: Can execute authorized trades through `manage()` and `manageBatch()` functions

### Key Features

- **UUPS Upgradeability**: Secure upgrade mechanism with owner-only authorization
- **Two-Step Ownership Transfer**: Prevents accidental ownership transfer with accept/transfer pattern
- **Authorization System**: Owners can authorize specific function signatures on target contracts
- **Spender Whitelist**: Special authorization for token approve operations to whitelisted addresses only
- **Spending Limits**: Time-windowed spending limits per token (e.g., max spend per 6 hours)
- **Token Tracking**: Track specific tokens for spending limit enforcement
- **Batch Operations**: Execute multiple authorized calls in a single transaction
- **Flexible Management**: Operators can execute arbitrary calls to authorized contracts
- **Safe Withdrawals**: Owner-only withdrawal functions for both ETH and ERC20 tokens (withdraws directly to owner)
- **Event Logging**: Comprehensive events for all major operations
- **Security**: Uses OpenZeppelin's ReentrancyGuard, SafeERC20, and Ownable2Step

## Installation

This project uses Foundry. Install dependencies:

```bash
forge install
```

## Usage

### Build

```bash
forge build
```

### Test

Run all tests:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvv
```

Run specific test:

```bash
forge test --match-test testFunctionName
```

### Gas Report

```bash
forge test --gas-report
```

### Format

```bash
forge fmt
```

### Deploy

#### Setup Environment

Create an `env.sh` file (use `env.sh.example` as template):

```bash
export PRIVATE_KEY=0x...
export RPC_URL=https://...
export OWNER_ADDRESS=0x...
export OPERATOR_ADDRESS=0x...
export ETHERSCAN_API_KEY=...
export LEGION_SAFE_ADDRESS=0x...  # Update after deployment
```

#### Production Deployment

Using the deploy script (recommended):

```bash
source env.sh
cd dev-scripts
bash deploy.sh
```

Or using Forge directly:

```bash
source env.sh
forge script script/Deploy.s.sol:DeployLegionSafe \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

**Important**: After deployment, update `LEGION_SAFE_ADDRESS` in `env.sh` with the deployed **proxy address** (not the implementation address).

#### Local Deployment (for testing)

```bash
forge script script/Deploy.s.sol:DeployLegionSafeLocal \
  --rpc-url http://localhost:8545 \
  --broadcast
```

#### Upgrading

To upgrade to a new implementation:

```bash
source env.sh
forge script script/Deploy.s.sol:UpgradeLegionSafe \
  --rpc-url $RPC_URL \
  --broadcast
```

#### Troubleshooting Deployment

**Etherscan API V2 Error**

If you get an error about deprecated Etherscan V1 endpoint during verification:

```
Error: You are using a deprecated V1 endpoint, switch to Etherscan API V2
```

Solution: Update Foundry to the latest version which supports Etherscan API V2:

```bash
foundryup
```

Then retry your deployment. The latest version of Foundry automatically uses the V2 API endpoints.

## Contract API

### Core Functions

#### Initialization

- `initialize(address _owner, address _operator)`: Initialize the contract (called once during deployment)

#### Authorization (Owner Only)

- `setCallAuthorization(address target, bytes4 selector, bool authorized)`: Authorize/revoke function calls
- `setSpenderWhitelist(address spender, bool whitelisted)`: Whitelist addresses for approve operations
- `setSpendingLimit(address token, uint256 limitPerWindow, uint256 windowDuration)`: Set spending limit for a token
- `addTrackedToken(address token)`: Add a token to spending tracking
- `removeTrackedToken(address token)`: Remove a token from spending tracking

#### Ownership (Owner Only)

- `transferOwnership(address newOwner)`: Initiate ownership transfer (two-step process)
- `acceptOwnership()`: Accept ownership transfer (called by new owner)
- `setOperator(address newOperator)`: Change the operator address

#### Management (Operator Only)

- `manage(address target, bytes calldata data, uint256 value)`: Execute authorized call to external contract
- `manageBatch(address[] targets, bytes[] data, uint256[] values)`: Execute multiple authorized calls in one transaction

#### Withdrawals (Owner Only)

- `withdrawETH(uint256 amount)`: Withdraw specific amount of ETH to owner
- `withdrawAllETH()`: Withdraw all ETH to owner
- `withdrawERC20(address token, uint256 amount)`: Withdraw specific amount of tokens to owner
- `withdrawAllERC20(address token)`: Withdraw all tokens to owner

#### Upgradeability (Owner Only)

- `upgradeToAndCall(address newImplementation, bytes calldata data)`: Upgrade to new implementation

#### View Functions

- `owner()`: Get current owner address
- `pendingOwner()`: Get pending owner address (two-step transfer)
- `operator()`: Get current operator address
- `getETHBalance()`: Get contract's ETH balance
- `getTokenBalance(address token)`: Get contract's token balance
- `authorizedCalls(address target, bytes4 selector)`: Check if a call is authorized
- `whitelistedSpenders(address spender)`: Check if a spender is whitelisted
- `spendingLimits(address token)`: Get spending limit configuration for a token
- `getRemainingLimit(address token)`: Get remaining spending limit in current window
- `getTrackedTokens()`: Get list of tracked tokens

## Spending Limits Feature

LegionSafe includes a sophisticated spending limit system to protect against excessive trading:

### How It Works

1. **Token Tracking**: Owner adds tokens to track (e.g., USDC, WBNB)
2. **Time Windows**: Spending is tracked in time windows (default: 6 hours)
3. **Limit Enforcement**: Operator's trades are limited to the configured amount per window
4. **Automatic Reset**: Limits automatically reset when a new window begins

### Configuration Example

```solidity
// Add USDC to tracked tokens
vault.addTrackedToken(0xUSDC_ADDRESS);

// Set limit: max 1000 USDC per 6 hours
vault.setSpendingLimit(
    0xUSDC_ADDRESS,
    1000e6,        // 1000 USDC (6 decimals)
    6 hours        // Window duration
);

// Check remaining limit
(uint256 remaining, uint256 windowEndsAt) = vault.getRemainingLimit(0xUSDC_ADDRESS);
```

### Use Cases

- **Risk Management**: Limit potential losses from operator's automated trades
- **Daily/Hourly Caps**: Set different windows (1 hour, 6 hours, 24 hours)
- **Multi-Token Limits**: Track and limit spending for different tokens independently
- **Native Token Limits**: Works with ETH/BNB using `address(0)`

## Example Usage

### TypeScript SDK (Recommended)

The easiest way to interact with LegionSafe is through the TypeScript SDK. See the [SDK README](sdk/README.md) for full documentation.

```typescript
import { LegionSafeClient } from "@legionsafe/sdk";
import {
  createPublicClient,
  createWalletClient,
  http,
  parseEther,
  parseUnits,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { bsc } from "viem/chains";

// Setup
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const publicClient = createPublicClient({ chain: bsc, transport: http() });
const walletClient = createWalletClient({
  account,
  chain: bsc,
  transport: http(),
});

const client = new LegionSafeClient({
  safeAddress: "0xYourSafeAddress",
  walletClient,
  publicClient,
});

// 1. Initial Setup (Owner)
await client.setSpenderWhitelist({
  spender: dexRouterAddress,
  whitelisted: true,
});
await client.authorizeCall({
  target: dexAddress,
  selector: swapSelector,
  authorized: true,
});
await client.addTrackedToken(usdcAddress);
await client.setSpendingLimit({
  token: usdcAddress,
  limitPerWindow: parseUnits("1000", 6),
  windowDuration: 6 * 3600,
});

// 2. Execute Trade (Operator) - Batch Operation
await client.manageBatch({
  calls: [
    { target: tokenAddress, data: approveCalldata, value: 0n },
    { target: dexAddress, data: swapCalldata, value: 0n },
  ],
});

// 3. Check Status
const balance = await client.getETHBalance();
const tokenBalance = await client.getTokenBalance(usdcAddress);
const { remaining, windowEndsAt } = await client.getRemainingLimit(usdcAddress);

// 4. Withdraw Profits (Owner)
await client.withdrawERC20({
  token: tokenAddress,
  amount: parseUnits("100", 18),
});
await client.withdrawAllETH();
```

**See the [SDK Documentation](sdk/README.md) for:**

- Complete API reference
- Working examples
- DEX integration guides (KyberSwap)
- Type-safe contract interaction

### Dev Scripts (Alternative)

For bash/CLI-based interaction, see the [dev-scripts README](dev-scripts/README.md):

```bash
# Source environment
source env.sh

# Check status
bash dev-scripts/check-status.sh

# Authorize and manage (owner)
bash dev-scripts/authorize-function.sh 0xDEX_ADDRESS "swap(address,address,uint256,uint256)" true

# Execute trades (operator)
bash dev-scripts/manage-call.sh 0xDEX_ADDRESS $CALLDATA 0

# Withdraw (owner)
bash dev-scripts/withdraw-erc20.sh 0xTOKEN_ADDRESS 1000000
```

## Security Considerations

- **UUPS Upgradeability**: Only owner can authorize upgrades, implementation validates upgrades
- **Two-Step Ownership**: Prevents accidental ownership transfer errors
- **Role-Based Access Control**: Owner and Operator have distinct, limited permissions
- **Reentrancy Protection**: NonReentrant modifier on manage() and withdrawal functions
- **Authorization Checks**: Validates both caller role and target function authorization
- **Spender Whitelist**: Token approvals only work with pre-whitelisted addresses
- **Spending Limits**: Time-windowed limits prevent excessive spending in short periods
- **Token Tracking**: Monitor and enforce spending on specific tokens
- **Custom Errors**: Gas-efficient error handling with clear error messages
- **SafeERC20**: Uses OpenZeppelin's SafeERC20 for safe token transfers
- **Comprehensive Event Logging**: All operations emit events for transparency and monitoring

## Testing

The test suite includes:

### Unit Tests (`test/LegionSafe.t.sol`)

- Initialization and deployment
- Owner and operator role management
- Authorization system
- Withdrawal functions
- Access control
- Edge cases

### Management Tests (`test/LegionSafe.mange.t.sol`)

- Manage function execution
- Batch operations
- Authorization validation
- Reentrancy protection

### Upgrade Tests (`test/LegionSafe.upgrade.t.sol`)

- UUPS upgrade mechanism
- State preservation across upgrades
- Upgrade authorization

### Fork Tests (`test/fork/`)

- Real-world integration with KyberSwap on BSC
- Live DEX interaction tests
- API integration tests

Run tests:

```bash
# All tests
forge test

# With verbosity
forge test -vvv

# Specific test file
forge test --match-path test/LegionSafe.t.sol

# Fork tests (requires RPC URL)
forge test --match-path test/fork/ --fork-url $RPC_URL

# Gas report
forge test --gas-report
```

## Dev Scripts

The repository includes a comprehensive set of bash scripts for deployment and contract interaction. See [dev-scripts/README.md](dev-scripts/README.md) for detailed documentation.

Available scripts:

- `deploy.sh` - Deploy contract with UUPS proxy
- `check-status.sh` - Check contract status
- `get-token-balance.sh` - Check token balances
- `authorize-function.sh` - Authorize function calls (owner)
- `set-operator.sh` - Change operator (owner)
- `withdraw-eth.sh` - Withdraw ETH (owner)
- `withdraw-erc20.sh` - Withdraw tokens (owner)
- `manage-call.sh` - Execute trades (operator)

## TypeScript SDK

**The recommended way to interact with LegionSafe is through the TypeScript SDK.**

The SDK provides a type-safe, developer-friendly interface for all LegionSafe operations including authorization, trade execution, withdrawals, spending limits, and more.

### Installation

```bash
npm install @legionsafe/sdk viem
```

### Quick Start

```typescript
import { LegionSafeClient } from "@legionsafe/sdk";

const client = new LegionSafeClient({
  safeAddress: "0xYourSafeAddress",
  walletClient,
  publicClient,
});

// Check balance
const balance = await client.getETHBalance();

// Execute trade
await client.manage({ target, data, value });

// Withdraw profits
await client.withdrawAllERC20(tokenAddress);
```

### SDK Features

- ✅ **Type-Safe**: Full TypeScript support with exported types
- 🔒 **Security**: Built-in validation and error handling
- 🚀 **Easy to Use**: Simple, intuitive API
- 🔄 **DEX Integration**: Built-in KyberSwap support
- 📦 **Batch Operations**: Execute multiple calls atomically
- 🛡️ **Spending Limits**: Manage time-windowed limits
- 📊 **Balance Queries**: Check vault balances
- ⬆️ **Upgrade Support**: UUPS proxy upgrades

### Documentation

- **[SDK README](sdk/README.md)** - Complete SDK documentation
- **[API Reference](sdk/docs/API.md)** - Detailed API documentation
- **[Examples](sdk/examples/)** - Working code examples

### Examples

The SDK includes complete working examples:

- `basic-usage.ts` - Query vault information and balances
- `kyberswap-swap.ts` - Execute DEX swaps through KyberSwap
- `authorize-and-manage.ts` - Authorize functions and execute calls
- `batch-operations.ts` - Execute multiple calls atomically
- `spending-limits.ts` - Configure and monitor spending limits
- `whitelist-spenders.ts` - Manage spender whitelist

See the [SDK README](sdk/README.md) for complete documentation and all examples.

## License

MIT

## Foundry Documentation

For more information on Foundry:

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Documentation](https://github.com/foundry-rs/foundry)
