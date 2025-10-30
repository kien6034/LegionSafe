import { Address } from 'viem';

/**
 * KyberSwap route summary
 */
export interface KyberSwapRouteSummary {
  tokenIn: string;
  amountIn: string;
  tokenOut: string;
  amountOut: string;
  gas: string;
  gasPrice: string;
  gasUsd: string;
  extraFee: {
    feeAmount: string;
    chargeFeeBy: string;
    isInBps: boolean;
    feeReceiver: string;
  };
  route: Array<Array<{
    pool: string;
    tokenIn: string;
    tokenOut: string;
    limitReturnAmount: string;
    swapAmount: string;
    amountOut: string;
    exchange: string;
    poolLength: number;
    poolType: string;
  }>>;
}

/**
 * KyberSwap route response
 */
export interface KyberSwapRoute {
  routeSummary: KyberSwapRouteSummary;
  routerAddress: string;
}

/**
 * Build route request parameters
 */
export interface KyberSwapBuildRouteRequest {
  routeSummary: KyberSwapRouteSummary;
  sender: string;
  recipient: string;
  slippageTolerance?: number;
}

/**
 * Build route response
 */
export interface KyberSwapBuildRouteResponse {
  amountIn: string;
  amountOut: string;
  gas: string;
  gasPrice: string;
  gasUsd: string;
  outputChange: {
    amount: string;
    percent: number;
    level: number;
  };
  data: string;
  routerAddress: string;
}

/**
 * Swap parameters for KyberSwap
 */
export interface KyberSwapParams {
  tokenIn: Address;
  tokenOut: Address;
  amountIn: string;
  sender: Address;
  recipient: Address;
  slippageTolerance?: number;
}
