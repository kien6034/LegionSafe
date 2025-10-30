import {
  createPublicClient,
  createWalletClient,
  http,
  parseEther,
  formatEther,
  formatUnits,
  type Address,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';
import * as fs from 'fs';
import { BSC_CONFIG, SWAP_CONFIG, TOKENS, KYBERSWAP_CONFIG } from './config.js';
import { LEGION_SAFE_ABI, ERC20_ABI } from './types.js';
import { KyberSwapClient } from './kyberswap-client.js';

interface DeploymentInfo {
  address: Address;
  owner: Address;
  operator: Address;
}

/**
 * Load deployment info
 */
function loadDeploymentInfo(): DeploymentInfo {
  if (!fs.existsSync('deployment.json')) {
    throw new Error('deployment.json not found. Run deploy.ts first.');
  }

  return JSON.parse(fs.readFileSync('deployment.json', 'utf-8'));
}

/**
 * Authorize KyberSwap router
 */
async function authorizeKyberSwap(
  privateKey: string,
  safeAddress: Address,
  routerAddress: Address
): Promise<void> {
  const account = privateKeyToAccount(privateKey as `0x${string}`);

  const publicClient = createPublicClient({
    chain: bsc,
    transport: http(BSC_CONFIG.rpcUrl),
  });

  const walletClient = createWalletClient({
    account,
    chain: bsc,
    transport: http(BSC_CONFIG.rpcUrl),
  });

  console.log('\n🔐 Authorizing KyberSwap Router...');
  console.log(`Router: ${routerAddress}`);

  // Get function selectors for KyberSwap router functions
  // We need to authorize all possible KyberSwap function selectors
  const selectors = [
    '0x8af033fb', // swapSimpleMode(address,SwapDescription,bytes,bytes)
    '0x59e50fed', // swap((address,address,address,address,uint256,bytes),SwapDescription,bytes,bytes)
    '0xe21fd0e9', // KyberSwap MetaAggregationRouterV2 function
  ];

  for (const selector of selectors) {
    console.log(`  Authorizing selector: ${selector}`);

    const hash = await walletClient.writeContract({
      address: safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'setCallAuthorization',
      args: [routerAddress, selector as `0x${string}`, true],
      account,
    });

    await publicClient.waitForTransactionReceipt({ hash });
    console.log(`  ✅ Authorized ${selector}`);
  }

  console.log('✅ KyberSwap router authorized!');
}

/**
 * Execute swap through LegionSafe
 */
async function executeSwap(
  privateKey: string,
  safeAddress: Address
): Promise<void> {
  const account = privateKeyToAccount(privateKey as `0x${string}`);

  const publicClient = createPublicClient({
    chain: bsc,
    transport: http(BSC_CONFIG.rpcUrl),
  });

  const walletClient = createWalletClient({
    account,
    chain: bsc,
    transport: http(BSC_CONFIG.rpcUrl),
  });

  console.log('\n🔄 Executing Swap through LegionSafe');
  console.log('━'.repeat(50));

  // Step 1: Check initial balances
  const initialBNB = await publicClient.readContract({
    address: safeAddress,
    abi: LEGION_SAFE_ABI,
    functionName: 'getETHBalance',
  });

  const initialUSDT = await publicClient.readContract({
    address: TOKENS.USDT,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [safeAddress],
  });

  console.log('\n📊 Initial Balances:');
  console.log(`   BNB: ${formatEther(initialBNB)}`);
  console.log(`   USDT: ${formatUnits(initialUSDT, 18)}`);

  // Step 2: Get route from KyberSwap
  const kyberClient = new KyberSwapClient();
  const amountInWei = parseEther(SWAP_CONFIG.amountInBNB).toString();

  const route = await kyberClient.getRoute(
    SWAP_CONFIG.tokenIn,
    SWAP_CONFIG.tokenOut,
    amountInWei
  );

  // Step 3: Build swap transaction
  const txData = await kyberClient.buildSwapTransaction(
    route,
    safeAddress, // sender is the LegionSafe
    safeAddress, // recipient is also the LegionSafe
    SWAP_CONFIG.slippageTolerance
  );

  // Step 4: Execute through manage()
  console.log('\n⚡ Executing swap via manage()...');
  console.log(`   Router: ${route.routerAddress}`);
  console.log(`   Value: ${SWAP_CONFIG.amountInBNB} BNB`);

  const hash = await walletClient.writeContract({
    address: safeAddress,
    abi: LEGION_SAFE_ABI,
    functionName: 'manage',
    args: [
      route.routerAddress as Address,
      txData.data as `0x${string}`,
      BigInt(amountInWei),
    ],
    account,
  });

  console.log(`📝 Transaction Hash: ${hash}`);
  console.log(`🔗 BSCScan: https://bscscan.com/tx/${hash}`);
  console.log('⏳ Waiting for confirmation...');

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  if (receipt.status !== 'success') {
    throw new Error('Swap transaction failed');
  }

  console.log('✅ Swap executed successfully!');

  // Step 5: Check final balances
  const finalBNB = await publicClient.readContract({
    address: safeAddress,
    abi: LEGION_SAFE_ABI,
    functionName: 'getETHBalance',
  });

  const finalUSDT = await publicClient.readContract({
    address: TOKENS.USDT,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [safeAddress],
  });

  console.log('\n📊 Final Balances:');
  console.log(`   BNB: ${formatEther(finalBNB)}`);
  console.log(`   USDT: ${formatUnits(finalUSDT, 18)}`);

  console.log('\n📈 Swap Results:');
  console.log(`   BNB Spent: ${formatEther(initialBNB - finalBNB)}`);
  console.log(`   USDT Received: ${formatUnits(finalUSDT - initialUSDT, 18)}`);
  console.log(`   Gas Used: ${receipt.gasUsed.toString()}`);
}

// Main execution
if (import.meta.url === `file://${process.argv[1]}`) {
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    console.error('❌ Error: PRIVATE_KEY environment variable not set');
    process.exit(1);
  }

  const deployment = loadDeploymentInfo();
  console.log(`\n🏦 LegionSafe Address: ${deployment.address}`);

  // First authorize KyberSwap
  authorizeKyberSwap(privateKey, deployment.address, KYBERSWAP_CONFIG.routerAddress)
    .then(() => executeSwap(privateKey, deployment.address))
    .catch((error) => {
      console.error('❌ Swap failed:', error);
      process.exit(1);
    });
}
