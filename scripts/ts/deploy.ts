import {
  createPublicClient,
  createWalletClient,
  http,
  parseEther,
  formatEther,
  type Address,
} from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { bsc } from 'viem/chains';
import * as fs from 'fs';
import * as path from 'path';
import { BSC_CONFIG } from './config.js';
import { LEGION_SAFE_ABI } from './types.js';

/**
 * Read LegionSafe bytecode from compiled artifact
 */
function getLegionSafeBytecode(): `0x${string}` {
  const artifactPath = path.join(process.cwd(), '../../out/LegionSafe.sol/LegionSafe.json');

  if (!fs.existsSync(artifactPath)) {
    throw new Error('LegionSafe.json not found. Run `forge build` first.');
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));
  return artifact.bytecode.object as `0x${string}`;
}

/**
 * Deploy LegionSafe contract
 */
export async function deployLegionSafe(
  privateKey: string,
  owner: Address,
  operator: Address
): Promise<Address> {
  // Setup clients
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

  console.log('\n📋 Deployment Configuration');
  console.log('━'.repeat(50));
  console.log(`Deployer: ${account.address}`);
  console.log(`Owner: ${owner}`);
  console.log(`Operator: ${operator}`);
  console.log(`Network: BSC Mainnet (Chain ID: ${BSC_CONFIG.chainId})`);

  // Check deployer balance
  const balance = await publicClient.getBalance({ address: account.address });
  console.log(`\n💰 Deployer Balance: ${formatEther(balance)} BNB`);

  // Get bytecode
  const bytecode = getLegionSafeBytecode();
  console.log(`\n📦 Contract Bytecode: ${bytecode.slice(0, 10)}... (${bytecode.length} bytes)`);

  // Deploy contract
  console.log('\n🚀 Deploying LegionSafe...');

  const hash = await walletClient.deployContract({
    abi: LEGION_SAFE_ABI,
    bytecode,
    args: [owner, operator],
    account,
  });

  console.log(`📝 Transaction Hash: ${hash}`);
  console.log('⏳ Waiting for confirmation...');

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  if (receipt.status !== 'success') {
    throw new Error('Deployment failed');
  }

  const contractAddress = receipt.contractAddress!;

  console.log('\n✅ Deployment Successful!');
  console.log('━'.repeat(50));
  console.log(`Contract Address: ${contractAddress}`);
  console.log(`Block Number: ${receipt.blockNumber}`);
  console.log(`Gas Used: ${receipt.gasUsed.toString()}`);
  console.log(`\n🔗 BSCScan: https://bscscan.com/address/${contractAddress}`);

  return contractAddress;
}

/**
 * Fund LegionSafe with BNB
 */
export async function fundLegionSafe(
  privateKey: string,
  safeAddress: Address,
  amount: string
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

  console.log('\n💸 Funding LegionSafe...');
  console.log(`Amount: ${amount} BNB`);

  const hash = await walletClient.sendTransaction({
    account,
    to: safeAddress,
    value: parseEther(amount),
  });

  console.log(`📝 Transaction Hash: ${hash}`);
  await publicClient.waitForTransactionReceipt({ hash });

  // Check balance
  const balance = await publicClient.readContract({
    address: safeAddress,
    abi: LEGION_SAFE_ABI,
    functionName: 'getETHBalance',
  });

  console.log(`✅ Safe funded! Balance: ${formatEther(balance)} BNB`);
}

// Main execution
if (import.meta.url === `file://${process.argv[1]}`) {
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    console.error('❌ Error: PRIVATE_KEY environment variable not set');
    process.exit(1);
  }

  const account = privateKeyToAccount(privateKey as `0x${string}`);
  const ownerOperator = account.address; // Same address for testing

  deployLegionSafe(privateKey, ownerOperator, ownerOperator)
    .then(async (address) => {
      // Fund with 0.0002 BNB (0.0001 for swap + 0.0001 buffer for gas)
      await fundLegionSafe(privateKey, address, '0.0002');

      // Save deployment info
      const deploymentInfo = {
        address,
        owner: ownerOperator,
        operator: ownerOperator,
        deployedAt: new Date().toISOString(),
        network: 'bsc',
      };

      fs.writeFileSync(
        'deployment.json',
        JSON.stringify(deploymentInfo, null, 2)
      );

      console.log('\n📄 Deployment info saved to deployment.json');
    })
    .catch((error) => {
      console.error('❌ Deployment failed:', error);
      process.exit(1);
    });
}
