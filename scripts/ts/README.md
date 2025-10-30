# LegionSafe TypeScript Scripts

TypeScript scripts for deploying LegionSafe and executing swaps via KyberSwap on BSC.

## Prerequisites

1. Node.js 18+ installed
2. Foundry installed (for building contracts)
3. BSC wallet with at least 0.2 BNB (~$120 at current prices)

## Setup

1. **Build Contracts:**
   ```bash
   cd ../..  # Go to project root
   forge build
   ```

2. **Install Dependencies:**
   ```bash
   cd scripts/ts
   npm install
   ```

3. **Configure Environment:**
   ```bash
   # In project root
   export PRIVATE_KEY=0x... # Your private key from env.sh
   ```

## Usage

### 1. Deploy LegionSafe

Deploys the contract with your wallet as both owner and operator (for testing):

```bash
npm run deploy
```

This will:
- Deploy LegionSafe contract
- Fund it with 0.15 BNB
- Save deployment info to `deployment.json`

Output:
```
📋 Deployment Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deployer: 0x...
Owner: 0x...
Operator: 0x...
Network: BSC Mainnet (Chain ID: 56)

💰 Deployer Balance: 0.004 BNB

🚀 Deploying LegionSafe...
✅ Deployment Successful!
Contract Address: 0x...
```

### 2. Execute Swap

Authorizes KyberSwap router and executes a 0.1 BNB → USDT swap:

```bash
npm run swap
```

This will:
- Authorize KyberSwap router functions
- Get optimal route from KyberSwap API
- Build swap transaction
- Execute via `manage()` function
- Display results

Output:
```
🔐 Authorizing KyberSwap Router...
✅ KyberSwap router authorized!

🔄 Executing Swap through LegionSafe
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Initial Balances:
   BNB: 0.15
   USDT: 0

🔍 Getting route from KyberSwap...
✅ Route found!
   Amount Out: 50000000000000000000

⚡ Executing swap via manage()...
✅ Swap executed successfully!

📊 Final Balances:
   BNB: 0.05
   USDT: 50.0

📈 Swap Results:
   BNB Spent: 0.1
   USDT Received: 50.0
```

## Files

- `types.ts` - TypeScript types and ABIs
- `config.ts` - Configuration (addresses, RPC, etc.)
- `kyberswap-client.ts` - KyberSwap API client
- `deploy.ts` - Deployment script
- `execute-swap.ts` - Swap execution script
- `deployment.json` - Saved deployment info (generated)

## Configuration

Edit `config.ts` to change:
- Swap amount (default: 0.1 BNB)
- Slippage tolerance (default: 0.5%)
- Token pair (default: BNB → USDT)
- RPC endpoint

## Troubleshooting

### "Insufficient BNB for deployment"
- Ensure wallet has at least 0.2 BNB

### "LegionSafe.json not found"
- Run `forge build` from project root

### "deployment.json not found"
- Run `npm run deploy` first

### "Swap transaction failed"
- Check KyberSwap router is authorized
- Verify safe has enough BNB
- Check slippage tolerance

## Security Notes

- Never commit private keys
- Use separate wallets for testing
- Verify contract addresses on BSCScan
- Start with small amounts

## Links

- [BSCScan](https://bscscan.com/)
- [KyberSwap Docs](https://docs.kyberswap.com/)
- [Viem Docs](https://viem.sh/)
