# LegionSafe SDK Examples

This directory contains example scripts demonstrating how to use the LegionSafe SDK.

## Setup

1. Install dependencies:
   ```bash
   cd sdk && npm install
   ```

2. Set environment variables:
   ```bash
   export PRIVATE_KEY="0x..."
   ```

3. Update the safe address in each example file

## Examples

### Basic Usage
Query vault information (owner, operator, balances)

```bash
npx tsx examples/basic-usage.ts
```

### KyberSwap Swap
Execute a token swap through KyberSwap aggregator

```bash
npx tsx examples/kyberswap-swap.ts
```

### Authorize and Manage
Authorize a function and execute arbitrary calls

```bash
npx tsx examples/authorize-and-manage.ts
```

## Key Concepts

- **Authorization**: Functions must be authorized before execution
- **Manage**: Execute authorized calls through the vault
- **Withdrawals**: Owner can withdraw ETH and tokens
- **Integrations**: Use DEX clients like KyberSwap for trading
