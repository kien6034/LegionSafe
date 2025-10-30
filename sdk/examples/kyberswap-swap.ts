import {
  LegionSafeClient,
  KyberSwapClient,
  KYBERSWAP_SELECTORS,
  NATIVE_TOKEN_ADDRESS,
} from '@legionsafe/sdk';
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';

/**
 * Example: Execute a swap through KyberSwap
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

  const safeAddress = '0xYourSafeAddress';
  const legionSafe = new LegionSafeClient({
    safeAddress,
    walletClient,
    publicClient,
  });

  const kyberswap = new KyberSwapClient(56); // BSC chain ID

  // Step 1: Authorize KyberSwap router
  console.log('Authorizing KyberSwap router...');

  for (const selector of Object.values(KYBERSWAP_SELECTORS)) {
    await legionSafe.authorizeCall({
      target: kyberswap.routerAddress,
      selector: selector as `0x${string}`,
      authorized: true,
    });
  }

  console.log('✓ Router authorized');

  // Step 2: Get swap calldata
  console.log('\nGetting swap route...');

  const usdtAddress = '0x55d398326f99059fF775485246999027B3197955';
  const amountIn = parseEther('0.01'); // 0.01 BNB

  const { calldata, amountOut, routerAddress } = await kyberswap.getSwapCalldata({
    tokenIn: NATIVE_TOKEN_ADDRESS,
    tokenOut: usdtAddress,
    amountIn: amountIn.toString(),
    sender: safeAddress,
    recipient: safeAddress,
    slippageTolerance: 50, // 0.5%
  });

  console.log(`✓ Expected output: ${amountOut} USDT`);

  // Step 3: Execute swap via manage()
  console.log('\nExecuting swap...');

  const result = await legionSafe.manage({
    target: routerAddress,
    data: calldata,
    value: amountIn,
  });

  console.log(`✓ Swap complete!`);
  console.log(`  Tx Hash: ${result.hash}`);
  console.log(`  Gas Used: ${result.gasUsed}`);

  // Step 4: Check new balance
  const newBalance = await legionSafe.getTokenBalance(usdtAddress);
  console.log(`\nNew USDT Balance: ${newBalance.formatted} ${newBalance.symbol}`);
}

main().catch(console.error);
