import { Address } from 'viem';

// BSC Mainnet Configuration
export const BSC_CONFIG = {
  chainId: 56,
  rpcUrl: 'https://bsc-dataseed1.binance.org',
  name: 'BSC',
  nativeCurrency: {
    name: 'BNB',
    symbol: 'BNB',
    decimals: 18
  }
};

// Token Addresses on BSC
export const TOKENS = {
  WBNB: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c' as Address,
  USDT: '0x55d398326f99059fF775485246999027B3197955' as Address,
  NATIVE: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE' as Address, // KyberSwap native token indicator
};

// KyberSwap Configuration
export const KYBERSWAP_CONFIG = {
  apiBase: 'https://aggregator-api.kyberswap.com',
  chainName: 'bsc',
  routerAddress: '0x6131B5fae19EA4f9D964eAc0408E4408b66337b5' as Address,
};

// Swap Configuration
export const SWAP_CONFIG = {
  amountInBNB: '0.0001', // 0.0001 BNB
  slippageTolerance: 50, // 0.5% (50 basis points)
  tokenIn: TOKENS.NATIVE,
  tokenOut: TOKENS.USDT,
};
