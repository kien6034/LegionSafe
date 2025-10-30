import { Address } from 'viem';
import {
  KyberSwapRoute,
  KyberSwapBuildRouteRequest,
  KyberSwapBuildRouteResponse,
  KyberSwapParams,
} from './types.js';
import {
  KYBERSWAP_API_BASE,
  KYBERSWAP_CHAIN_NAMES,
  KYBERSWAP_ROUTERS,
} from './constants.js';

/**
 * Client for interacting with KyberSwap Aggregator API
 */
export class KyberSwapClient {
  private apiBase: string;
  private chainName: string;
  public readonly routerAddress: Address;

  constructor(chainId: number) {
    this.apiBase = KYBERSWAP_API_BASE;

    const chainName = KYBERSWAP_CHAIN_NAMES[chainId];
    if (!chainName) {
      throw new Error(`Unsupported chain ID: ${chainId}`);
    }
    this.chainName = chainName;

    const routerAddress = KYBERSWAP_ROUTERS[chainId];
    if (!routerAddress) {
      throw new Error(`No KyberSwap router for chain ID: ${chainId}`);
    }
    this.routerAddress = routerAddress;
  }

  /**
   * Get the best swap route from KyberSwap
   */
  async getRoute(
    tokenIn: Address,
    tokenOut: Address,
    amountIn: string
  ): Promise<KyberSwapRoute> {
    const url = `${this.apiBase}/${this.chainName}/api/v1/routes?tokenIn=${tokenIn}&tokenOut=${tokenOut}&amountIn=${amountIn}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`KyberSwap API error: ${response.status} - ${error}`);
    }

    const data = await response.json() as { data: KyberSwapRoute };
    return data.data;
  }

  /**
   * Build swap transaction calldata
   */
  async buildSwap(
    route: KyberSwapRoute,
    sender: Address,
    recipient: Address,
    slippageTolerance: number = 50
  ): Promise<KyberSwapBuildRouteResponse> {
    const url = `${this.apiBase}/${this.chainName}/api/v1/route/build`;

    const buildRequest: KyberSwapBuildRouteRequest = {
      routeSummary: route.routeSummary,
      sender,
      recipient,
      slippageTolerance,
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildRequest),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`KyberSwap build API error: ${response.status} - ${error}`);
    }

    const data = await response.json() as { data: KyberSwapBuildRouteResponse };
    return data.data;
  }

  /**
   * Get swap calldata in one call (combines getRoute + buildSwap)
   */
  async getSwapCalldata(params: KyberSwapParams): Promise<{
    calldata: `0x${string}`;
    amountOut: string;
    routerAddress: Address;
  }> {
    const route = await this.getRoute(
      params.tokenIn,
      params.tokenOut,
      params.amountIn
    );

    const txData = await this.buildSwap(
      route,
      params.sender,
      params.recipient,
      params.slippageTolerance ?? 50
    );

    return {
      calldata: txData.data as `0x${string}`,
      amountOut: txData.amountOut,
      routerAddress: this.routerAddress,
    };
  }
}
