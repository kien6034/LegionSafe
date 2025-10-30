import { Address, WalletClient, PublicClient, Hash } from 'viem';

/**
 * Configuration for LegionSafe client
 */
interface LegionSafeConfig {
    /** Address of the deployed LegionSafe contract */
    safeAddress: Address;
    /** Wallet client for signing transactions */
    walletClient: WalletClient;
    /** Public client for reading contract state */
    publicClient: PublicClient;
}
/**
 * Parameters for authorizing a function call
 */
interface AuthorizeCallParams {
    /** Target contract address */
    target: Address;
    /** 4-byte function selector */
    selector: `0x${string}`;
    /** Whether to authorize or revoke */
    authorized: boolean;
}
/**
 * Parameters for executing a call via manage()
 */
interface ManageCallParams {
    /** Target contract address */
    target: Address;
    /** Encoded calldata */
    data: `0x${string}`;
    /** Native token value to send (in wei) */
    value: bigint;
}
/**
 * Parameters for withdrawing ETH
 */
interface WithdrawETHParams {
    /** Recipient address */
    recipient: Address;
    /** Amount to withdraw in wei */
    amount: bigint;
}
/**
 * Parameters for withdrawing ERC20 tokens
 */
interface WithdrawERC20Params {
    /** Token contract address */
    token: Address;
    /** Recipient address */
    recipient: Address;
    /** Amount to withdraw (in token's smallest unit) */
    amount: bigint;
}
/**
 * Transaction result
 */
interface TransactionResult {
    /** Transaction hash */
    hash: Hash;
    /** Block number where transaction was included */
    blockNumber: bigint;
    /** Gas used */
    gasUsed: bigint;
    /** Transaction status */
    status: 'success' | 'reverted';
}
/**
 * Balance information
 */
interface BalanceInfo {
    /** Balance in wei/smallest unit */
    raw: bigint;
    /** Formatted balance as string */
    formatted: string;
    /** Number of decimals */
    decimals: number;
    /** Token symbol (if applicable) */
    symbol?: string;
}

/**
 * Main SDK client for interacting with LegionSafe contracts
 */
declare class LegionSafeClient {
    readonly safeAddress: Address;
    private readonly walletClient;
    private readonly publicClient;
    constructor(config: LegionSafeConfig);
    /**
     * Get the current account address
     */
    private getAccount;
    /**
     * Wait for transaction and return result
     */
    private waitForTransaction;
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
    authorizeCall(params: AuthorizeCallParams): Promise<TransactionResult>;
    /**
     * Check if a function call is authorized
     *
     * @param target Target contract address
     * @param selector 4-byte function selector
     * @returns Whether the call is authorized
     */
    isCallAuthorized(target: Address, selector: `0x${string}`): Promise<boolean>;
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
    manage(params: ManageCallParams): Promise<TransactionResult & {
        returnData: `0x${string}`;
    }>;
    /**
     * Withdraw ETH from the vault (owner only)
     *
     * @param params Withdrawal parameters
     * @returns Transaction result
     */
    withdrawETH(params: WithdrawETHParams): Promise<TransactionResult>;
    /**
     * Withdraw all ETH from the vault (owner only)
     *
     * @param recipient Recipient address
     * @returns Transaction result
     */
    withdrawAllETH(recipient: Address): Promise<TransactionResult>;
    /**
     * Withdraw ERC20 tokens from the vault (owner only)
     *
     * @param params Withdrawal parameters
     * @returns Transaction result
     */
    withdrawERC20(params: WithdrawERC20Params): Promise<TransactionResult>;
    /**
     * Withdraw all ERC20 tokens from the vault (owner only)
     *
     * @param token Token address
     * @param recipient Recipient address
     * @returns Transaction result
     */
    withdrawAllERC20(token: Address, recipient: Address): Promise<TransactionResult>;
    /**
     * Get the vault's native token balance
     *
     * @returns Balance information
     */
    getETHBalance(): Promise<BalanceInfo>;
    /**
     * Get the vault's ERC20 token balance
     *
     * @param token Token address
     * @returns Balance information with symbol
     */
    getTokenBalance(token: Address): Promise<BalanceInfo>;
    /**
     * Get the vault's owner address
     */
    getOwner(): Promise<Address>;
    /**
     * Get the vault's operator address
     */
    getOperator(): Promise<Address>;
    /**
     * Transfer ownership to a new address (owner only)
     *
     * @param newOwner New owner address
     * @returns Transaction result
     */
    transferOwnership(newOwner: Address): Promise<TransactionResult>;
    /**
     * Set a new operator address (owner only)
     *
     * @param newOperator New operator address
     * @returns Transaction result
     */
    setOperator(newOperator: Address): Promise<TransactionResult>;
}

/**
 * LegionSafe contract ABI
 */
declare const LEGION_SAFE_ABI: readonly [{
    readonly type: "constructor";
    readonly inputs: readonly [{
        readonly name: "_owner";
        readonly type: "address";
    }, {
        readonly name: "_operator";
        readonly type: "address";
    }];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "owner";
    readonly inputs: readonly [];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "address";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "operator";
    readonly inputs: readonly [];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "address";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "setCallAuthorization";
    readonly inputs: readonly [{
        readonly name: "target";
        readonly type: "address";
    }, {
        readonly name: "selector";
        readonly type: "bytes4";
    }, {
        readonly name: "authorized";
        readonly type: "bool";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "manage";
    readonly inputs: readonly [{
        readonly name: "target";
        readonly type: "address";
    }, {
        readonly name: "data";
        readonly type: "bytes";
    }, {
        readonly name: "value";
        readonly type: "uint256";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "bytes";
    }];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "transferOwnership";
    readonly inputs: readonly [{
        readonly name: "newOwner";
        readonly type: "address";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "setOperator";
    readonly inputs: readonly [{
        readonly name: "newOperator";
        readonly type: "address";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "withdrawETH";
    readonly inputs: readonly [{
        readonly name: "recipient";
        readonly type: "address";
    }, {
        readonly name: "amount";
        readonly type: "uint256";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "withdrawAllETH";
    readonly inputs: readonly [{
        readonly name: "recipient";
        readonly type: "address";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "withdrawERC20";
    readonly inputs: readonly [{
        readonly name: "token";
        readonly type: "address";
    }, {
        readonly name: "recipient";
        readonly type: "address";
    }, {
        readonly name: "amount";
        readonly type: "uint256";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "withdrawAllERC20";
    readonly inputs: readonly [{
        readonly name: "token";
        readonly type: "address";
    }, {
        readonly name: "recipient";
        readonly type: "address";
    }];
    readonly outputs: readonly [];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "getETHBalance";
    readonly inputs: readonly [];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "uint256";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "getTokenBalance";
    readonly inputs: readonly [{
        readonly name: "token";
        readonly type: "address";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "uint256";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "authorizedCalls";
    readonly inputs: readonly [{
        readonly name: "target";
        readonly type: "address";
    }, {
        readonly name: "selector";
        readonly type: "bytes4";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "bool";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "event";
    readonly name: "CallAuthorized";
    readonly inputs: readonly [{
        readonly name: "target";
        readonly type: "address";
        readonly indexed: true;
    }, {
        readonly name: "selector";
        readonly type: "bytes4";
        readonly indexed: true;
    }, {
        readonly name: "authorized";
        readonly type: "bool";
        readonly indexed: false;
    }];
}, {
    readonly type: "event";
    readonly name: "Managed";
    readonly inputs: readonly [{
        readonly name: "target";
        readonly type: "address";
        readonly indexed: true;
    }, {
        readonly name: "data";
        readonly type: "bytes";
        readonly indexed: false;
    }, {
        readonly name: "value";
        readonly type: "uint256";
        readonly indexed: false;
    }];
}, {
    readonly type: "receive";
    readonly stateMutability: "payable";
}];
/**
 * ERC20 token ABI (minimal)
 */
declare const ERC20_ABI: readonly [{
    readonly type: "function";
    readonly name: "balanceOf";
    readonly inputs: readonly [{
        readonly name: "account";
        readonly type: "address";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "uint256";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "decimals";
    readonly inputs: readonly [];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "uint8";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "symbol";
    readonly inputs: readonly [];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "string";
    }];
    readonly stateMutability: "view";
}, {
    readonly type: "function";
    readonly name: "approve";
    readonly inputs: readonly [{
        readonly name: "spender";
        readonly type: "address";
    }, {
        readonly name: "amount";
        readonly type: "uint256";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "bool";
    }];
    readonly stateMutability: "nonpayable";
}, {
    readonly type: "function";
    readonly name: "transfer";
    readonly inputs: readonly [{
        readonly name: "to";
        readonly type: "address";
    }, {
        readonly name: "amount";
        readonly type: "uint256";
    }];
    readonly outputs: readonly [{
        readonly name: "";
        readonly type: "bool";
    }];
    readonly stateMutability: "nonpayable";
}];

/**
 * Common chain IDs
 */
declare const CHAIN_IDS: {
    readonly ETHEREUM: 1;
    readonly BSC: 56;
    readonly POLYGON: 137;
    readonly ARBITRUM: 42161;
    readonly BASE: 8453;
};
/**
 * Native token addresses (used by some DEX aggregators)
 */
declare const NATIVE_TOKEN_ADDRESS: Address;
/**
 * Zero address
 */
declare const ZERO_ADDRESS: Address;

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
declare function getFunctionSelector(input: string): `0x${string}`;
/**
 * Check if an address is the zero address
 */
declare function isZeroAddress(address: Address): boolean;
/**
 * Validate that a value is a valid address
 */
declare function isValidAddress(value: string): value is Address;
/**
 * Format a transaction hash for display with ellipsis
 */
declare function formatHash(hash: string, startChars?: number, endChars?: number): string;

/**
 * KyberSwap route summary
 */
interface KyberSwapRouteSummary {
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
interface KyberSwapRoute {
    routeSummary: KyberSwapRouteSummary;
    routerAddress: string;
}
/**
 * Build route request parameters
 */
interface KyberSwapBuildRouteRequest {
    routeSummary: KyberSwapRouteSummary;
    sender: string;
    recipient: string;
    slippageTolerance?: number;
}
/**
 * Build route response
 */
interface KyberSwapBuildRouteResponse {
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
interface KyberSwapParams {
    tokenIn: Address;
    tokenOut: Address;
    amountIn: string;
    sender: Address;
    recipient: Address;
    slippageTolerance?: number;
}

/**
 * Client for interacting with KyberSwap Aggregator API
 */
declare class KyberSwapClient {
    private apiBase;
    private chainName;
    readonly routerAddress: Address;
    constructor(chainId: number);
    /**
     * Get the best swap route from KyberSwap
     */
    getRoute(tokenIn: Address, tokenOut: Address, amountIn: string): Promise<KyberSwapRoute>;
    /**
     * Build swap transaction calldata
     */
    buildSwap(route: KyberSwapRoute, sender: Address, recipient: Address, slippageTolerance?: number): Promise<KyberSwapBuildRouteResponse>;
    /**
     * Get swap calldata in one call (combines getRoute + buildSwap)
     */
    getSwapCalldata(params: KyberSwapParams): Promise<{
        calldata: `0x${string}`;
        amountOut: string;
        routerAddress: Address;
    }>;
}

/**
 * KyberSwap API endpoints by chain
 */
declare const KYBERSWAP_API_BASE = "https://aggregator-api.kyberswap.com";
/**
 * KyberSwap chain names
 */
declare const KYBERSWAP_CHAIN_NAMES: Record<number, string>;
/**
 * KyberSwap router addresses by chain
 */
declare const KYBERSWAP_ROUTERS: Record<number, Address>;
/**
 * Common function selectors for KyberSwap
 */
declare const KYBERSWAP_SELECTORS: {
    readonly SWAP_SIMPLE_MODE: "0x8af033fb";
    readonly SWAP: "0x59e50fed";
    readonly META_AGGREGATION: "0xe21fd0e9";
};

export { type AuthorizeCallParams, type BalanceInfo, CHAIN_IDS, ERC20_ABI, KYBERSWAP_API_BASE, KYBERSWAP_CHAIN_NAMES, KYBERSWAP_ROUTERS, KYBERSWAP_SELECTORS, type KyberSwapBuildRouteRequest, type KyberSwapBuildRouteResponse, KyberSwapClient, type KyberSwapParams, type KyberSwapRoute, type KyberSwapRouteSummary, LEGION_SAFE_ABI, LegionSafeClient, type LegionSafeConfig, type ManageCallParams, NATIVE_TOKEN_ADDRESS, type TransactionResult, type WithdrawERC20Params, type WithdrawETHParams, ZERO_ADDRESS, formatHash, getFunctionSelector, isValidAddress, isZeroAddress };
