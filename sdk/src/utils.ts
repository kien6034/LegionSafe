import { Address, keccak256, toBytes } from 'viem';

/**
 * Extract 4-byte function selector from calldata or function signature
 *
 * @param input Calldata (0x...) or function signature ("transfer(address,uint256)")
 * @returns 4-byte selector
 *
 * @example
 * ```typescript
 * getFunctionSelector('0x12345678...')  // '0x12345678'
 * getFunctionSelector('transfer(address,uint256)')  // '0xa9059cbb'
 * ```
 */
export function getFunctionSelector(input: string): `0x${string}` {
  if (input.startsWith('0x')) {
    // Already calldata - extract first 4 bytes
    return input.slice(0, 10) as `0x${string}`;
  }

  // Function signature - hash and extract first 4 bytes
  const hash = keccak256(toBytes(input));
  return hash.slice(0, 10) as `0x${string}`;
}

/**
 * Check if an address is the zero address
 */
export function isZeroAddress(address: Address): boolean {
  return address === '0x0000000000000000000000000000000000000000';
}

/**
 * Validate that a value is a valid address
 */
export function isValidAddress(value: string): value is Address {
  return /^0x[a-fA-F0-9]{40}$/.test(value);
}

/**
 * Format a transaction hash for display with ellipsis
 */
export function formatHash(hash: string, startChars = 6, endChars = 4): string {
  if (hash.length < startChars + endChars + 2) return hash;
  return `${hash.slice(0, startChars + 2)}...${hash.slice(-endChars)}`;
}
