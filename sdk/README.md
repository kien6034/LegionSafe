# LegionSafe SDK

TypeScript SDK for interacting with LegionSafe smart contracts. Build secure, automated trading strategies with role-based access control.

## Features

- 🔐 **Authorization Management** - Control which functions can be called
- ⚡ **Arbitrary Call Execution** - Execute any authorized call through `manage()`
- 🔀 **Batch Operations** - Execute multiple calls atomically with `manageBatch()`
- 💰 **Withdrawal Functions** - Owner-controlled ETH and ERC20 withdrawals
- 🔄 **DEX Integrations** - Built-in KyberSwap aggregator support
- 📊 **Balance Queries** - Check vault balances for ETH and tokens
- 🛡️ **Type-Safe** - Full TypeScript support with exported types
- 🌐 **Multi-Chain** - Support for Ethereum, BSC, Polygon, Arbitrum, Base

## Installation

```bash
npm install @legionsafe/sdk viem
```

## Quick Start

```typescript
import { LegionSafeClient } from '@legionsafe/sdk';
import { createPublicClient, createWalletClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';

// Setup clients
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const publicClient = createPublicClient({
  chain: bsc,
  transport: http(),
});
const walletClient = createWalletClient({
  account,
  chain: bsc,
  transport: http(),
});

// Create LegionSafe client
const client = new LegionSafeClient({
  safeAddress: '0xYourSafeAddress',
  walletClient,
  publicClient,
});

// Authorize a function
await client.authorizeCall({
  target: '0xRouterAddress',
  selector: '0x12345678',
  authorized: true,
});

// Execute call via manage()
await client.manage({
  target: '0xTargetAddress',
  data: '0xcalldata...',
  value: 0n,
});
```

## Core Concepts

### Authorization

Before executing any call through `manage()`, the function must be authorized:

```typescript
// Authorize ERC20 approve function
const selector = getFunctionSelector('approve(address,uint256)');
await client.authorizeCall({
  target: tokenAddress,
  selector,
  authorized: true,
});
```

### Execute Arbitrary Calls

Use `manage()` to execute any authorized call:

```typescript
const calldata = encodeFunctionData({
  abi: parseAbi(['function approve(address,uint256)']),
  functionName: 'approve',
  args: [spenderAddress, amount],
});

await client.manage({
  target: tokenAddress,
  data: calldata,
  value: 0n, // ETH to send
});
```

### Batch Operations

Execute multiple calls atomically with `manageBatch()`. All calls succeed or fail together:

```typescript
import { encodeFunctionData, parseAbi, parseEther } from 'viem';

// Build approve calldata
const approveCalldata = encodeFunctionData({
  abi: parseAbi(['function approve(address,uint256)']),
  functionName: 'approve',
  args: [routerAddress, parseEther('100')],
});

// Build swap calldata
const swapCalldata = encodeFunctionData({
  abi: parseAbi(['function swap(address,address,uint256)']),
  functionName: 'swap',
  args: [tokenIn, tokenOut, parseEther('100')],
});

// Execute both atomically
await client.manageBatch({
  calls: [
    { target: tokenAddress, data: approveCalldata, value: 0n },
    { target: routerAddress, data: swapCalldata, value: 0n }
  ]
});
```

**Benefits:**
- ⚛️ Atomic execution (all-or-nothing)
- ⛽ Gas savings vs. multiple transactions
- 🔒 Prevents partial execution (e.g., approve without swap)

### Withdrawals

Owner can withdraw funds from the vault to their own address:

```typescript
// Withdraw specific amount of ETH to owner
await client.withdrawETH({
  amount: parseEther('1.0'),
});

// Withdraw all ETH to owner
await client.withdrawAllETH();

// Withdraw specific amount of ERC20 tokens to owner
await client.withdrawERC20({
  token: '0xTokenAddress',
  amount: parseUnits('100', 18),
});

// Withdraw all ERC20 tokens to owner
await client.withdrawAllERC20('0xTokenAddress');
```

### DEX Integrations

Built-in support for KyberSwap:

```typescript
import { KyberSwapClient, KYBERSWAP_SELECTORS } from '@legionsafe/sdk';

const kyberswap = new KyberSwapClient(56); // BSC

// Get swap calldata
const { calldata, routerAddress } = await kyberswap.getSwapCalldata({
  tokenIn: NATIVE_TOKEN_ADDRESS,
  tokenOut: usdtAddress,
  amountIn: parseEther('0.1').toString(),
  sender: safeAddress,
  recipient: safeAddress,
});

// Execute swap
await client.manage({
  target: routerAddress,
  data: calldata,
  value: parseEther('0.1'),
});
```

## API Reference

See [API Documentation](./docs/API.md) for complete API reference.

## Examples

Check the [examples/](./examples/) directory for complete working examples:

- **basic-usage.ts** - Query vault information
- **kyberswap-swap.ts** - Execute DEX swaps
- **authorize-and-manage.ts** - Authorize and execute calls
- **batch-operations.ts** - Execute multiple calls atomically

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run tests
npm test

# Type check
npm run typecheck
```

## License

MIT
