import { Address, Hash, formatUnits } from 'viem';
import { LEGION_SAFE_ABI, ERC20_ABI } from './abis.js';
import type {
  LegionSafeConfig,
  AuthorizeCallParams,
  ManageCallParams,
  ManageBatchParams,
  WithdrawETHParams,
  WithdrawERC20Params,
  TransactionResult,
  BalanceInfo,
} from './types.js';

/**
 * Main SDK client for interacting with LegionSafe contracts
 */
export class LegionSafeClient {
  public readonly safeAddress: Address;
  private readonly walletClient;
  private readonly publicClient;

  constructor(config: LegionSafeConfig) {
    this.safeAddress = config.safeAddress;
    this.walletClient = config.walletClient;
    this.publicClient = config.publicClient;
  }

  /**
   * Get the current account address
   */
  private getAccount() {
    if (!this.walletClient.account) {
      throw new Error('Wallet client must have an account');
    }
    return this.walletClient.account;
  }

  /**
   * Wait for transaction and return result
   */
  private async waitForTransaction(hash: Hash): Promise<TransactionResult> {
    const receipt = await this.publicClient.waitForTransactionReceipt({ hash });

    return {
      hash,
      blockNumber: receipt.blockNumber,
      gasUsed: receipt.gasUsed,
      status: receipt.status,
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
  async authorizeCall(params: AuthorizeCallParams): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'setCallAuthorization',
      args: [params.target, params.selector, params.authorized],
      account: this.getAccount(),
      chain: this.walletClient.chain,
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
  async isCallAuthorized(
    target: Address,
    selector: `0x${string}`
  ): Promise<boolean> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'authorizedCalls',
      args: [target, selector],
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
  async manage(params: ManageCallParams): Promise<TransactionResult & { returnData: `0x${string}` }> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'manage',
      args: [params.target, params.data, params.value],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    const result = await this.waitForTransaction(hash);

    return {
      ...result,
      returnData: '0x', // Return data is available in logs
    };
  }

  /**
   * Execute multiple calls atomically through the vault's manageBatch() function
   *
   * @param params Batch call parameters
   * @returns Transaction result with array of returned data
   *
   * @example
   * ```typescript
   * await client.manageBatch({
   *   calls: [
   *     { target: tokenAddress, data: approveCalldata, value: 0n },
   *     { target: routerAddress, data: swapCalldata, value: parseEther('0.1') }
   *   ]
   * });
   * ```
   */
  async manageBatch(params: ManageBatchParams): Promise<TransactionResult & { returnData: `0x${string}`[] }> {
    // Transform object array into separate arrays for contract call
    const targets = params.calls.map(call => call.target);
    const data = params.calls.map(call => call.data);
    const values = params.calls.map(call => call.value);

    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'manageBatch',
      args: [targets, data, values],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    const result = await this.waitForTransaction(hash);

    return {
      ...result,
      returnData: [], // Return data available in logs
    };
  }

  /**
   * Withdraw ETH from the vault to the owner (owner only)
   *
   * @param params Withdrawal parameters
   * @returns Transaction result
   */
  async withdrawETH(params: WithdrawETHParams): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'withdrawETH',
      args: [params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Withdraw all ETH from the vault to the owner (owner only)
   *
   * @returns Transaction result
   */
  async withdrawAllETH(): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'withdrawAllETH',
      args: [],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Withdraw ERC20 tokens from the vault to the owner (owner only)
   *
   * @param params Withdrawal parameters
   * @returns Transaction result
   */
  async withdrawERC20(params: WithdrawERC20Params): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'withdrawERC20',
      args: [params.token, params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Withdraw all ERC20 tokens from the vault to the owner (owner only)
   *
   * @param token Token address
   * @returns Transaction result
   */
  async withdrawAllERC20(token: Address): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'withdrawAllERC20',
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Get the vault's native token balance
   *
   * @returns Balance information
   */
  async getETHBalance(): Promise<BalanceInfo> {
    const balance = await this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'getETHBalance',
    });

    return {
      raw: balance,
      formatted: formatUnits(balance, 18),
      decimals: 18,
    };
  }

  /**
   * Get the vault's ERC20 token balance
   *
   * @param token Token address
   * @returns Balance information with symbol
   */
  async getTokenBalance(token: Address): Promise<BalanceInfo> {
    const [balance, decimals, symbol] = await Promise.all([
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: 'getTokenBalance',
        args: [token],
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: 'decimals',
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: 'symbol',
      }),
    ]);

    return {
      raw: balance,
      formatted: formatUnits(balance, decimals),
      decimals,
      symbol,
    };
  }

  /**
   * Get the vault's owner address
   */
  async getOwner(): Promise<Address> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'owner',
    });
  }

  /**
   * Get the vault's operator address
   */
  async getOperator(): Promise<Address> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'operator',
    });
  }

  /**
   * Transfer ownership to a new address (owner only)
   *
   * @param newOwner New owner address
   * @returns Transaction result
   */
  async transferOwnership(newOwner: Address): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'transferOwnership',
      args: [newOwner],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Set a new operator address (owner only)
   *
   * @param newOperator New operator address
   * @returns Transaction result
   */
  async setOperator(newOperator: Address): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: 'setOperator',
      args: [newOperator],
      account: this.getAccount(),
      chain: this.walletClient.chain,
    });

    return this.waitForTransaction(hash);
  }
}
