// KyberSwap API Types
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

export interface KyberSwapRoute {
  routeSummary: KyberSwapRouteSummary;
  routerAddress: string;
}

export interface KyberSwapBuildRouteRequest {
  routeSummary: KyberSwapRouteSummary;
  sender: string;
  recipient: string;
  slippageTolerance?: number;
}

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

export interface DeploymentConfig {
  privateKey: string;
  rpcUrl: string;
  owner: string;
  operator: string;
}

export interface SwapConfig {
  amountIn: string; // in wei
  tokenIn: string;
  tokenOut: string;
  slippage: number;
}

// Contract ABIs
export const LEGION_SAFE_ABI = [
  {
    type: 'constructor',
    inputs: [
      { name: '_owner', type: 'address' },
      { name: '_operator', type: 'address' }
    ],
    stateMutability: 'nonpayable'
  },
  {
    type: 'function',
    name: 'setCallAuthorization',
    inputs: [
      { name: 'target', type: 'address' },
      { name: 'selector', type: 'bytes4' },
      { name: 'authorized', type: 'bool' }
    ],
    outputs: [],
    stateMutability: 'nonpayable'
  },
  {
    type: 'function',
    name: 'manage',
    inputs: [
      { name: 'target', type: 'address' },
      { name: 'data', type: 'bytes' },
      { name: 'value', type: 'uint256' }
    ],
    outputs: [{ name: '', type: 'bytes' }],
    stateMutability: 'nonpayable'
  },
  {
    type: 'function',
    name: 'owner',
    inputs: [],
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'operator',
    inputs: [],
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'getETHBalance',
    inputs: [],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'getTokenBalance',
    inputs: [{ name: 'token', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view'
  },
  {
    type: 'receive',
    stateMutability: 'payable'
  }
] as const;

export const ERC20_ABI = [
  {
    type: 'function',
    name: 'balanceOf',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'decimals',
    inputs: [],
    outputs: [{ name: '', type: 'uint8' }],
    stateMutability: 'view'
  },
  {
    type: 'function',
    name: 'symbol',
    inputs: [],
    outputs: [{ name: '', type: 'string' }],
    stateMutability: 'view'
  }
] as const;
