import { Address, Hash, PublicClient, WalletClient } from "viem";

/**
 * Optional gas configuration for transactions
 */
export interface GasOptions {
  /** Gas limit for the transaction */
  gas?: bigint;
  /** Gas price for legacy transactions (in wei) */
  gasPrice?: bigint;
  /** Max fee per gas for EIP-1559 transactions (in wei) */
  maxFeePerGas?: bigint;
  /** Max priority fee per gas for EIP-1559 transactions (in wei) */
  maxPriorityFeePerGas?: bigint;
}

/**
 * Configuration for LegionSafe client
 */
export interface LegionSafeConfig {
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
export interface AuthorizeCallParams {
  /** Target contract address */
  target: Address;
  /** 4-byte function selector */
  selector: `0x${string}`;
  /** Whether to authorize or revoke */
  authorized: boolean;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Parameters for executing a call via manage()
 */
export interface ManageCallParams {
  /** Target contract address */
  target: Address;
  /** Encoded calldata */
  data: `0x${string}`;
  /** Native token value to send (in wei) */
  value: bigint;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Single call in a batch operation
 */
export interface BatchCallItem {
  /** Target contract address */
  target: Address;
  /** Encoded calldata */
  data: `0x${string}`;
  /** Native token value to send (in wei) */
  value: bigint;
}

/**
 * Parameters for executing batch calls via manageBatch()
 */
export interface ManageBatchParams {
  /** Array of calls to execute */
  calls: BatchCallItem[];
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Parameters for withdrawing ETH
 */
export interface WithdrawETHParams {
  /** Amount to withdraw in wei */
  amount: bigint;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Parameters for withdrawing ERC20 tokens
 */
export interface WithdrawERC20Params {
  /** Token contract address */
  token: Address;
  /** Amount to withdraw (in token's smallest unit) */
  amount: bigint;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Transaction result
 */
export interface TransactionResult {
  /** Transaction hash */
  hash: Hash;
  /** Block number where transaction was included */
  blockNumber: bigint;
  /** Gas used */
  gasUsed: bigint;
  /** Transaction status */
  status: "success" | "reverted";
}

/**
 * Balance information
 */
export interface BalanceInfo {
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
 * Parameters for whitelisting a spender
 */
export interface SetSpenderWhitelistParams {
  /** Spender address to whitelist/remove */
  spender: Address;
  /** Whether to whitelist (true) or remove (false) */
  whitelisted: boolean;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Parameters for setting a spending limit
 */
export interface SetSpendingLimitParams {
  /** Token address (use 0x0 for native token) */
  token: Address;
  /** Maximum amount per window */
  limitPerWindow: bigint;
  /** Window duration in seconds (0 = use default 6 hours) */
  windowDuration?: bigint;
  /** Optional gas configuration */
  gasOptions?: GasOptions;
}

/**
 * Spending limit information
 */
export interface SpendingLimitInfo {
  /** Maximum amount per window */
  limitPerWindow: bigint;
  /** Window duration in seconds */
  windowDuration: bigint;
  /** Amount spent in current window */
  spent: bigint;
  /** Timestamp when current window started */
  lastWindowStart: bigint;
  /** Amount remaining in current window */
  remaining: bigint;
  /** Timestamp when current window ends */
  windowEndsAt: bigint;
}
