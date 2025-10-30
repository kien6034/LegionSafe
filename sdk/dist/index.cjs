'use strict';

var viem = require('viem');

// src/LegionSafeClient.ts

// src/abis.ts
var LEGION_SAFE_ABI = [
  {
    type: "constructor",
    inputs: [
      { name: "_owner", type: "address" },
      { name: "_operator", type: "address" }
    ],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "operator",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "setCallAuthorization",
    inputs: [
      { name: "target", type: "address" },
      { name: "selector", type: "bytes4" },
      { name: "authorized", type: "bool" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "manage",
    inputs: [
      { name: "target", type: "address" },
      { name: "data", type: "bytes" },
      { name: "value", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bytes" }],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "transferOwnership",
    inputs: [{ name: "newOwner", type: "address" }],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "setOperator",
    inputs: [{ name: "newOperator", type: "address" }],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "withdrawETH",
    inputs: [
      { name: "amount", type: "uint256" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "withdrawAllETH",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "withdrawERC20",
    inputs: [
      { name: "token", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "withdrawAllERC20",
    inputs: [
      { name: "token", type: "address" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "getETHBalance",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "getTokenBalance",
    inputs: [{ name: "token", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "authorizedCalls",
    inputs: [
      { name: "target", type: "address" },
      { name: "selector", type: "bytes4" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view"
  },
  {
    type: "event",
    name: "CallAuthorized",
    inputs: [
      { name: "target", type: "address", indexed: true },
      { name: "selector", type: "bytes4", indexed: true },
      { name: "authorized", type: "bool", indexed: false }
    ]
  },
  {
    type: "event",
    name: "Managed",
    inputs: [
      { name: "target", type: "address", indexed: true },
      { name: "data", type: "bytes", indexed: false },
      { name: "value", type: "uint256", indexed: false }
    ]
  },
  {
    type: "receive",
    stateMutability: "payable"
  }
];
var ERC20_ABI = [
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "decimals",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "symbol",
    inputs: [],
    outputs: [{ name: "", type: "string" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "approve",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "transfer",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable"
  }
];

// src/LegionSafeClient.ts
var LegionSafeClient = class {
  safeAddress;
  walletClient;
  publicClient;
  constructor(config) {
    this.safeAddress = config.safeAddress;
    this.walletClient = config.walletClient;
    this.publicClient = config.publicClient;
  }
  /**
   * Get the current account address
   */
  getAccount() {
    if (!this.walletClient.account) {
      throw new Error("Wallet client must have an account");
    }
    return this.walletClient.account;
  }
  /**
   * Wait for transaction and return result
   */
  async waitForTransaction(hash) {
    const receipt = await this.publicClient.waitForTransactionReceipt({ hash });
    return {
      hash,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed,
      status: receipt.status
    };
  }
  /**
   * Authorize or revoke a function call
   *
   * @param params Authorization parameters
   * @returns Transaction result
   *
   * @example
   * ```typescript
   * await client.authorizeCall({
   *   target: '0xRouterAddress',
   *   selector: '0x12345678',
   *   authorized: true,
   * });
   * ```
   */
  async authorizeCall(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setCallAuthorization",
      args: [params.target, params.selector, params.authorized],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Check if a function call is authorized
   *
   * @param target Target contract address
   * @param selector 4-byte function selector
   * @returns Whether the call is authorized
   */
  async isCallAuthorized(target, selector) {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "authorizedCalls",
      args: [target, selector]
    });
  }
  /**
   * Execute an arbitrary call through the vault's manage() function
   *
   * @param params Manage call parameters
   * @returns Transaction result with returned data
   *
   * @example
   * ```typescript
   * // Execute a DEX swap
   * await client.manage({
   *   target: '0xRouterAddress',
   *   data: '0x...',  // encoded swap calldata
   *   value: parseEther('0.1'),  // 0.1 native token
   * });
   * ```
   */
  async manage(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "manage",
      args: [params.target, params.data, params.value],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    const result = await this.waitForTransaction(hash);
    return {
      ...result,
      returnData: "0x"
      // Return data is available in logs
    };
  }
  /**
   * Withdraw ETH from the vault to the owner (owner only)
   *
   * @param params Withdrawal parameters
   * @returns Transaction result
   */
  async withdrawETH(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawETH",
      args: [params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Withdraw all ETH from the vault to the owner (owner only)
   *
   * @returns Transaction result
   */
  async withdrawAllETH() {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllETH",
      args: [],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Withdraw ERC20 tokens from the vault to the owner (owner only)
   *
   * @param params Withdrawal parameters
   * @returns Transaction result
   */
  async withdrawERC20(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawERC20",
      args: [params.token, params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Withdraw all ERC20 tokens from the vault to the owner (owner only)
   *
   * @param token Token address
   * @returns Transaction result
   */
  async withdrawAllERC20(token) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllERC20",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Get the vault's native token balance
   *
   * @returns Balance information
   */
  async getETHBalance() {
    const balance = await this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "getETHBalance"
    });
    return {
      raw: balance,
      formatted: viem.formatUnits(balance, 18),
      decimals: 18
    };
  }
  /**
   * Get the vault's ERC20 token balance
   *
   * @param token Token address
   * @returns Balance information with symbol
   */
  async getTokenBalance(token) {
    const [balance, decimals, symbol] = await Promise.all([
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: "getTokenBalance",
        args: [token]
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: "decimals"
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: "symbol"
      })
    ]);
    return {
      raw: balance,
      formatted: viem.formatUnits(balance, decimals),
      decimals,
      symbol
    };
  }
  /**
   * Get the vault's owner address
   */
  async getOwner() {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "owner"
    });
  }
  /**
   * Get the vault's operator address
   */
  async getOperator() {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "operator"
    });
  }
  /**
   * Transfer ownership to a new address (owner only)
   *
   * @param newOwner New owner address
   * @returns Transaction result
   */
  async transferOwnership(newOwner) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "transferOwnership",
      args: [newOwner],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Set a new operator address (owner only)
   *
   * @param newOperator New operator address
   * @returns Transaction result
   */
  async setOperator(newOperator) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setOperator",
      args: [newOperator],
      account: this.getAccount(),
      chain: this.walletClient.chain
    });
    return this.waitForTransaction(hash);
  }
};

// src/constants.ts
var CHAIN_IDS = {
  ETHEREUM: 1,
  BSC: 56,
  POLYGON: 137,
  ARBITRUM: 42161,
  BASE: 8453
};
var NATIVE_TOKEN_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
var ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
function getFunctionSelector(input) {
  if (input.startsWith("0x")) {
    return input.slice(0, 10);
  }
  const hash = viem.keccak256(viem.toBytes(input));
  return hash.slice(0, 10);
}
function isZeroAddress(address) {
  return address === "0x0000000000000000000000000000000000000000";
}
function isValidAddress(value) {
  return /^0x[a-fA-F0-9]{40}$/.test(value);
}
function formatHash(hash, startChars = 6, endChars = 4) {
  if (hash.length < startChars + endChars + 2) return hash;
  return `${hash.slice(0, startChars + 2)}...${hash.slice(-endChars)}`;
}

// src/integrations/kyberswap/constants.ts
var KYBERSWAP_API_BASE = "https://aggregator-api.kyberswap.com";
var KYBERSWAP_CHAIN_NAMES = {
  1: "ethereum",
  56: "bsc",
  137: "polygon",
  42161: "arbitrum",
  8453: "base"
};
var KYBERSWAP_ROUTERS = {
  1: "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5",
  56: "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5",
  137: "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5",
  42161: "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5",
  8453: "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5"
};
var KYBERSWAP_SELECTORS = {
  SWAP_SIMPLE_MODE: "0x8af033fb",
  SWAP: "0x59e50fed",
  META_AGGREGATION: "0xe21fd0e9"
};

// src/integrations/kyberswap/client.ts
var KyberSwapClient = class {
  apiBase;
  chainName;
  routerAddress;
  constructor(chainId) {
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
  async getRoute(tokenIn, tokenOut, amountIn) {
    const url = `${this.apiBase}/${this.chainName}/api/v1/routes?tokenIn=${tokenIn}&tokenOut=${tokenOut}&amountIn=${amountIn}`;
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "application/json"
      }
    });
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`KyberSwap API error: ${response.status} - ${error}`);
    }
    const data = await response.json();
    return data.data;
  }
  /**
   * Build swap transaction calldata
   */
  async buildSwap(route, sender, recipient, slippageTolerance = 50) {
    const url = `${this.apiBase}/${this.chainName}/api/v1/route/build`;
    const buildRequest = {
      routeSummary: route.routeSummary,
      sender,
      recipient,
      slippageTolerance
    };
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(buildRequest)
    });
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`KyberSwap build API error: ${response.status} - ${error}`);
    }
    const data = await response.json();
    return data.data;
  }
  /**
   * Get swap calldata in one call (combines getRoute + buildSwap)
   */
  async getSwapCalldata(params) {
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
      calldata: txData.data,
      amountOut: txData.amountOut,
      routerAddress: this.routerAddress
    };
  }
};

exports.CHAIN_IDS = CHAIN_IDS;
exports.ERC20_ABI = ERC20_ABI;
exports.KYBERSWAP_API_BASE = KYBERSWAP_API_BASE;
exports.KYBERSWAP_CHAIN_NAMES = KYBERSWAP_CHAIN_NAMES;
exports.KYBERSWAP_ROUTERS = KYBERSWAP_ROUTERS;
exports.KYBERSWAP_SELECTORS = KYBERSWAP_SELECTORS;
exports.KyberSwapClient = KyberSwapClient;
exports.LEGION_SAFE_ABI = LEGION_SAFE_ABI;
exports.LegionSafeClient = LegionSafeClient;
exports.NATIVE_TOKEN_ADDRESS = NATIVE_TOKEN_ADDRESS;
exports.ZERO_ADDRESS = ZERO_ADDRESS;
exports.formatHash = formatHash;
exports.getFunctionSelector = getFunctionSelector;
exports.isValidAddress = isValidAddress;
exports.isZeroAddress = isZeroAddress;
//# sourceMappingURL=index.cjs.map
//# sourceMappingURL=index.cjs.map