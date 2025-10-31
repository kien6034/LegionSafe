# manageBatch SDK Method Design

**Date:** 2025-10-31
**Status:** Approved
**Author:** Claude Code

## Overview

Add `manageBatch()` method to the LegionSafe SDK to enable atomic execution of multiple authorized calls in a single transaction. The smart contract already implements `manageBatch()` (LegionSafe.sol:286-301), but the SDK currently only exposes single-call `manage()`.

## Motivation

**Use Cases:**
- Execute approve + swap atomically (prevents partial execution)
- Batch multiple swaps or operations for gas efficiency
- Complex multi-step strategies that must succeed or fail together

**Benefits:**
- Gas savings vs. multiple transactions
- Atomic execution (all-or-nothing)
- Type-safe API prevents common errors (array misalignment)

## Design

### API Choice: Object Array Pattern

Selected the **object array API** over alternatives:

```typescript
// ✅ Chosen: Object array (prevents misalignment errors)
await client.manageBatch({
  calls: [
    { target: '0x...', data: '0x...', value: 0n },
    { target: '0x...', data: '0x...', value: 0n }
  ]
});

// ❌ Rejected: Separate arrays (error-prone)
await client.manageBatch({
  targets: ['0x...', '0x...'],
  data: ['0x...', '0x...'],
  values: [0n, 0n]
});

// ❌ Rejected: Builder pattern (over-engineered)
await client.batch()
  .add('0x...', '0x...', 0n)
  .add('0x...', '0x...', 0n)
  .execute();
```

**Rationale:** Object array prevents array misalignment bugs while maintaining simplicity.

### Type Definitions

Add to `sdk/src/types.ts`:

```typescript
/**
 * Single call in a batch operation
 */
export interface BatchCallItem {
  /** Target contract address */
  target: Address;
  /** Encoded calldata */
  data: `0x${string}`;
  /** Native token value to send (in wei) */
  value: bigint;
}

/**
 * Parameters for executing batch calls via manageBatch()
 */
export interface ManageBatchParams {
  /** Array of calls to execute */
  calls: BatchCallItem[];
}
```

### Method Implementation

Add to `LegionSafeClient.ts` after `manage()` method:

```typescript
/**
 * Execute multiple calls atomically through the vault's manageBatch() function
 *
 * @param params Batch call parameters
 * @returns Transaction result with array of returned data
 *
 * @example
 * ```typescript
 * await client.manageBatch({
 *   calls: [
 *     { target: tokenAddress, data: approveCalldata, value: 0n },
 *     { target: routerAddress, data: swapCalldata, value: parseEther('0.1') }
 *   ]
 * });
 * ```
 */
async manageBatch(params: ManageBatchParams): Promise<TransactionResult & { returnData: `0x${string}`[] }> {
  // Transform object array into separate arrays for contract call
  const targets = params.calls.map(call => call.target);
  const data = params.calls.map(call => call.data);
  const values = params.calls.map(call => call.value);

  const hash = await this.walletClient.writeContract({
    address: this.safeAddress,
    abi: LEGION_SAFE_ABI,
    functionName: 'manageBatch',
    args: [targets, data, values],
    account: this.getAccount(),
    chain: this.walletClient.chain,
  });

  const result = await this.waitForTransaction(hash);

  return {
    ...result,
    returnData: [], // Return data available in logs
  };
}
```

**Implementation Notes:**
- Transforms user-friendly object array to contract-compatible arrays internally
- Follows same pattern as `manage()` method
- Returns `TransactionResult & { returnData: 0x${string}[] }` matching `manage()` signature
- Return data array placeholder (actual data in transaction logs)

### Exports

Update `sdk/src/types.ts`:
```typescript
export type { BatchCallItem, ManageBatchParams };
```

Already exported via barrel export in `sdk/src/index.ts`.

## Example Usage

Create `sdk/examples/batch-operations.ts`:

```typescript
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
```

## Testing Strategy

- Unit test: Verify array transformation (object array → separate arrays)
- Integration test: Execute batch with mock contract
- Error handling: Test invalid inputs, mismatched types

## Documentation Updates

Update `sdk/README.md` to include batch operations example in relevant sections.

## Implementation Checklist

1. Add type definitions to `types.ts`
2. Implement `manageBatch()` method in `LegionSafeClient.ts`
3. Export new types
4. Create example file `batch-operations.ts`
5. Update README.md with batch usage
6. Add tests (if test infrastructure exists)
7. Build and verify TypeScript compilation
