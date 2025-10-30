import { Address, Hash, PublicClient, WalletClient } from 'viem';

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
}

/**
 * Parameters for withdrawing ETH
 */
export interface WithdrawETHParams {
  /** Recipient address */
  recipient: Address;
  /** Amount to withdraw in wei */
  amount: bigint;
}

/**
 * Parameters for withdrawing ERC20 tokens
 */
export interface WithdrawERC20Params {
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
export interface TransactionResult {
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
