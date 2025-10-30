# LegionSafe SDK

TypeScript SDK for interacting with LegionSafe smart contracts.

## Installation

```bash
npm install @legionsafe/sdk viem
```

## Quick Start

```typescript
import { LegionSafeClient } from '@legionsafe/sdk';
import { createWalletClient, http } from 'viem';
import { bsc } from 'viem/chains';

// Create client
const client = new LegionSafeClient({
  safeAddress: '0x...',
  walletClient: walletClient,
  publicClient: publicClient,
});

// Authorize a function call
await client.authorizeCall({
  target: '0xRouterAddress',
  selector: '0x12345678',
  authorized: true,
});

// Execute arbitrary call via manage()
await client.manage({
  target: '0xTargetAddress',
  data: '0xcalldata...',
  value: 0n,
});
```

## Documentation

[Full documentation](https://github.com/...)
