import { Address } from 'viem';

/**
 * KyberSwap API endpoints by chain
 */
export const KYBERSWAP_API_BASE = 'https://aggregator-api.kyberswap.com';

/**
 * KyberSwap chain names
 */
export const KYBERSWAP_CHAIN_NAMES: Record<number, string> = {
  1: 'ethereum',
  56: 'bsc',
  137: 'polygon',
  42161: 'arbitrum',
  8453: 'base',
};

/**
 * KyberSwap router addresses by chain
 */
export const KYBERSWAP_ROUTERS: Record<number, Address> = {
  1: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
  56: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
  137: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
  42161: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
  8453: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5',
};

/**
 * Common function selectors for KyberSwap
 */
export const KYBERSWAP_SELECTORS = {
  SWAP_SIMPLE_MODE: '0x8af033fb',
  SWAP: '0x59e50fed',
  META_AGGREGATION: '0xe21fd0e9',
} as const;
