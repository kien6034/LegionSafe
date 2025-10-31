# LegionSafe SDK

TypeScript SDK for interacting with LegionSafe smart contracts. Build secure, automated trading strategies with role-based access control.

## Features

- 🔐 **Authorization Management** - Control which functions can be called
- ⚡ **Arbitrary Call Execution** - Execute any authorized call through `manage()`
- 🔀 **Batch Operations** - Execute multiple calls atomically with `manageBatch()`
- 💰 **Withdrawal Functions** - Owner-controlled ETH and ERC20 withdrawals (withdraws to owner)
- 🛡️ **Spending Limits** - Time-windowed spending limits per token for risk management
- ✅ **Spender Whitelist** - Whitelist addresses for safe token approval operations
- 📈 **Token Tracking** - Track and monitor spending across specific tokens
- 🔄 **DEX Integrations** - Built-in KyberSwap aggregator support
- 📊 **Balance Queries** - Check vault balances for ETH and tokens
- 🔓 **Two-Step Ownership** - Secure ownership transfer with accept/transfer pattern
- ⬆️ **Upgradeable** - UUPS proxy pattern support for contract upgrades
- 🛡️ **Type-Safe** - Full TypeScript support with exported types
- 🌐 **Multi-Chain** - Support for Ethereum, BSC, Polygon, Arbitrum, Base

## Installation

```bash
npm install @legionsafe/sdk viem
```

## Quick Start

```typescript
import { LegionSafeClient } from "@legionsafe/sdk";
import { createPublicClient, createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { bsc } from "viem/chains";

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
  safeAddress: "0xYourSafeAddress",
  walletClient,
  publicClient,
});

// Authorize a function
await client.authorizeCall({
  target: "0xRouterAddress",
  selector: "0x12345678",
  authorized: true,
});

// Execute call via manage()
await client.manage({
  target: "0xTargetAddress",
  data: "0xcalldata...",
  value: 0n,
});
```

## Core Concepts

### Authorization

Before executing any call through `manage()`, the function must be authorized:

```typescript
// Authorize ERC20 approve function
const selector = getFunctionSelector("approve(address,uint256)");
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
  abi: parseAbi(["function approve(address,uint256)"]),
  functionName: "approve",
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
import { encodeFunctionData, parseAbi, parseEther } from "viem";

// Build approve calldata
const approveCalldata = encodeFunctionData({
  abi: parseAbi(["function approve(address,uint256)"]),
  functionName: "approve",
  args: [routerAddress, parseEther("100")],
});

// Build swap calldata
const swapCalldata = encodeFunctionData({
  abi: parseAbi(["function swap(address,address,uint256)"]),
  functionName: "swap",
  args: [tokenIn, tokenOut, parseEther("100")],
});

// Execute both atomically
await client.manageBatch({
  calls: [
    { target: tokenAddress, data: approveCalldata, value: 0n },
    { target: routerAddress, data: swapCalldata, value: 0n },
  ],
});
```

**Benefits:**

- ⚛️ Atomic execution (all-or-nothing)
- ⛽ Gas savings vs. multiple transactions
- 🔒 Prevents partial execution (e.g., approve without swap)

### Withdrawals

Owner can withdraw funds from the vault directly to their own address:

```typescript
// Withdraw specific amount of ETH to owner
await client.withdrawETH({
  amount: parseEther("1.0"),
});

// Withdraw all ETH to owner
await client.withdrawAllETH();

// Withdraw specific amount of ERC20 tokens to owner
await client.withdrawERC20({
  token: "0xTokenAddress",
  amount: parseUnits("100", 18),
});

// Withdraw all ERC20 tokens to owner
await client.withdrawAllERC20("0xTokenAddress");
```

Note: All withdrawals go directly to the contract owner's address (no recipient parameter needed).

### Spending Limits

Protect against excessive trading with time-windowed spending limits:

```typescript
// Add token to tracking list
await client.addTrackedToken("0xUSDC_ADDRESS");

// Set spending limit: max 1000 USDC per 6 hours
await client.setSpendingLimit({
  token: "0xUSDC_ADDRESS",
  limitPerWindow: parseUnits("1000", 6), // 1000 USDC
  windowDuration: 6 * 3600, // 6 hours in seconds
});

// Check remaining limit
const { remaining, windowEndsAt } = await client.getRemainingLimit(
  "0xUSDC_ADDRESS"
);
console.log(
  `Can spend ${remaining} more until ${new Date(windowEndsAt * 1000)}`
);

// Get all tracked tokens
const trackedTokens = await client.getTrackedTokens();

// Remove token from tracking
await client.removeTrackedToken("0xUSDC_ADDRESS");
```

**How it works:**

- Spending is tracked in time windows (e.g., 6 hours)
- Operator's trades are limited to the configured amount per window
- Limits automatically reset when a new window begins
- Track native token (ETH/BNB) using `address(0)`
- Multiple tokens can have different limits

### Spender Whitelist

Whitelist addresses for safe token approval operations:

```typescript
// Whitelist a DEX router for approvals
await client.setSpenderWhitelist({
  spender: "0xRouterAddress",
  whitelisted: true,
});

// Now operator can approve tokens to this router
const approveCalldata = encodeFunctionData({
  abi: parseAbi(["function approve(address,uint256)"]),
  functionName: "approve",
  args: ["0xRouterAddress", parseEther("100")],
});

await client.manage({
  target: tokenAddress,
  data: approveCalldata,
  value: 0n,
});

// Remove from whitelist
await client.setSpenderWhitelist({
  spender: "0xRouterAddress",
  whitelisted: false,
});
```

**Security:** Approve calls only work if the spender is whitelisted, preventing unauthorized token approvals.

### Ownership Management

Two-step ownership transfer for enhanced security:

```typescript
// Current owner initiates transfer
await client.transferOwnership("0xNewOwnerAddress");

// New owner accepts ownership (using their wallet)
const newOwnerClient = new LegionSafeClient({
  safeAddress: "0xYourSafeAddress",
  walletClient: newOwnerWalletClient,
  publicClient,
});
await newOwnerClient.acceptOwnership();

// Check pending owner
const pendingOwner = await client.pendingOwner();
```

### Contract Upgrades

Upgrade to new implementation using UUPS pattern:

```typescript
// Deploy new implementation
const newImplementationAddress = "0xNewImplementationAddress";

// Upgrade (owner only)
await client.upgradeToAndCall({
  newImplementation: newImplementationAddress,
  data: "0x", // Optional initialization data
});
```

**Note:** State is preserved across upgrades. Only the contract logic is updated.

### DEX Integrations

Built-in support for KyberSwap:

```typescript
import { KyberSwapClient, KYBERSWAP_SELECTORS } from "@legionsafe/sdk";

const kyberswap = new KyberSwapClient(56); // BSC

// Get swap calldata
const { calldata, routerAddress } = await kyberswap.getSwapCalldata({
  tokenIn: NATIVE_TOKEN_ADDRESS,
  tokenOut: usdtAddress,
  amountIn: parseEther("0.1").toString(),
  sender: safeAddress,
  recipient: safeAddress,
});

// Execute swap
await client.manage({
  target: routerAddress,
  data: calldata,
  value: parseEther("0.1"),
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
