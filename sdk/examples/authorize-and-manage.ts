import {
  LegionSafeClient,
  getFunctionSelector,
} from '@legionsafe/sdk';
import { createPublicClient, createWalletClient, http, encodeFunctionData, parseAbi } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';

/**
 * Example: Authorize a function and execute arbitrary call
 */
async function main() {
  // Setup
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

  const client = new LegionSafeClient({
    safeAddress: '0xYourSafeAddress',
    walletClient,
    publicClient,
  });

  // Example: Authorize and execute ERC20 approve
  const tokenAddress = '0x55d398326f99059fF775485246999027B3197955'; // USDT
  const spenderAddress = '0xSpenderAddress';

  // Step 1: Get function selector
  const approveSelector = getFunctionSelector('approve(address,uint256)');
  console.log(`Approve selector: ${approveSelector}`);

  // Step 2: Authorize the function
  console.log('\nAuthorizing approve function...');
  await client.authorizeCall({
    target: tokenAddress,
    selector: approveSelector,
    authorized: true,
  });
  console.log('✓ Function authorized');

  // Step 3: Build calldata using viem
  const amount = 1000000000000000000n; // 1 token (18 decimals)
  const calldata = encodeFunctionData({
    abi: parseAbi(['function approve(address,uint256)']),
    functionName: 'approve',
    args: [spenderAddress, amount],
  });

  // Step 4: Execute via manage()
  console.log('\nExecuting approve...');
  const result = await client.manage({
    target: tokenAddress,
    data: calldata,
    value: 0n,
  });

  console.log(`✓ Approve complete!`);
  console.log(`  Tx Hash: ${result.hash}`);
  console.log(`  Gas Used: ${result.gasUsed}`);

  // Step 5: Verify authorization
  const isAuthorized = await client.isCallAuthorized(
    tokenAddress,
    approveSelector
  );
  console.log(`\nFunction still authorized: ${isAuthorized}`);
}

main().catch(console.error);
