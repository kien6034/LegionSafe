import { LegionSafeClient } from '@legionsafe/sdk';
import { createPublicClient, createWalletClient, http } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';

/**
 * Basic usage example: Query vault information
 */
async function main() {
  // Setup clients
  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);

  const publicClient = createPublicClient({
    chain: bsc,
    transport: http('https://bsc-dataseed1.binance.org'),
  });

  const walletClient = createWalletClient({
    account,
    chain: bsc,
    transport: http('https://bsc-dataseed1.binance.org'),
  });

  // Create SDK client
  const client = new LegionSafeClient({
    safeAddress: '0xYourSafeAddress',
    walletClient,
    publicClient,
  });

  // Query vault information
  console.log('Vault Information:');
  console.log('━'.repeat(50));

  const [owner, operator, ethBalance] = await Promise.all([
    client.getOwner(),
    client.getOperator(),
    client.getETHBalance(),
  ]);

  console.log(`Owner: ${owner}`);
  console.log(`Operator: ${operator}`);
  console.log(`ETH Balance: ${ethBalance.formatted} ETH`);

  // Query token balance
  const usdtAddress = '0x55d398326f99059fF775485246999027B3197955';
  const usdtBalance = await client.getTokenBalance(usdtAddress);
  console.log(`USDT Balance: ${usdtBalance.formatted} ${usdtBalance.symbol}`);
}

main().catch(console.error);
