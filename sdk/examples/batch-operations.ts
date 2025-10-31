import { LegionSafeClient } from '@legionsafe/sdk';
import { encodeFunctionData, parseAbi, parseEther } from 'viem';

// Example: Approve + Swap atomically
const approveCalldata = encodeFunctionData({
  abi: parseAbi(['function approve(address,uint256)']),
  functionName: 'approve',
  args: [routerAddress, parseEther('100')],
});

const swapCalldata = encodeFunctionData({
  abi: parseAbi(['function swap(address,address,uint256)']),
  functionName: 'swap',
  args: [tokenIn, tokenOut, parseEther('100')],
});

const result = await client.manageBatch({
  calls: [
    { target: tokenAddress, data: approveCalldata, value: 0n },
    { target: routerAddress, data: swapCalldata, value: 0n }
  ]
});

console.log('Batch executed:', result.hash);
