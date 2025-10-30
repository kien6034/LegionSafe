import { Address } from 'viem';

/**
 * Common chain IDs
 */
export const CHAIN_IDS = {
  ETHEREUM: 1,
  BSC: 56,
  POLYGON: 137,
  ARBITRUM: 42161,
  BASE: 8453,
} as const;

/**
 * Native token addresses (used by some DEX aggregators)
 */
export const NATIVE_TOKEN_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE' as Address;

/**
 * Zero address
 */
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000' as Address;
