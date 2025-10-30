import { Address } from 'viem';
import { KYBERSWAP_CONFIG } from './config.js';
import type {
  KyberSwapRoute,
  KyberSwapBuildRouteRequest,
  KyberSwapBuildRouteResponse,
} from './types.js';

export class KyberSwapClient {
  private apiBase: string;
  private chainName: string;

  constructor() {
    this.apiBase = KYBERSWAP_CONFIG.apiBase;
    this.chainName = KYBERSWAP_CONFIG.chainName;
  }

  /**
   * Get optimal swap route from KyberSwap
   */
  async getRoute(
    tokenIn: Address,
    tokenOut: Address,
    amountIn: string
  ): Promise<KyberSwapRoute> {
    const url = `${this.apiBase}/${this.chainName}/api/v1/routes?tokenIn=${tokenIn}&tokenOut=${tokenOut}&amountIn=${amountIn}`;

    console.log('🔍 Getting route from KyberSwap...');
    console.log(`   Token In: ${tokenIn}`);
    console.log(`   Token Out: ${tokenOut}`);
    console.log(`   Amount In: ${amountIn}`);

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

    console.log('✅ Route found!');
    console.log(`   Amount Out: ${data.data.routeSummary.amountOut}`);
    console.log(`   Router: ${data.data.routerAddress}`);
    console.log(`   Gas Estimate: ${data.data.routeSummary.gas}`);

    return data.data;
  }

  /**
   * Build swap transaction data
   */
  async buildSwapTransaction(
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

    console.log('🔨 Building swap transaction...');
    console.log(`   Sender: ${sender}`);
    console.log(`   Recipient: ${recipient}`);
    console.log(`   Slippage: ${slippageTolerance / 100}%`);

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

    console.log('✅ Transaction built!');
    console.log(`   Calldata length: ${data.data.data.length} bytes`);

    return data.data;
  }
}
