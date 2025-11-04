import {
  Address,
  Hash,
  formatUnits,
  encodeFunctionData,
  decodeErrorResult,
} from "viem";
import { LEGION_SAFE_ABI, ERC20_ABI } from "./abis.js";
import type {
  LegionSafeConfig,
  AuthorizeCallParams,
  ManageCallParams,
  ManageBatchParams,
  WithdrawETHParams,
  WithdrawERC20Params,
  TransactionResult,
  BalanceInfo,
  SetSpenderWhitelistParams,
  SetSpendingLimitParams,
  SpendingLimitInfo,
  GasOptions,
} from "./types.js";

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
      throw new Error("Wallet client must have an account");
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
      functionName: "setCallAuthorization",
      args: [params.target, params.selector, params.authorized],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
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
      functionName: "authorizedCalls",
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
  async manage(
    params: ManageCallParams
  ): Promise<TransactionResult & { returnData: `0x${string}` }> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "manage",
      args: [params.target, params.data, params.value],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    const result = await this.waitForTransaction(hash);

    return {
      ...result,
      returnData: "0x", // Return data is available in logs
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
  async manageBatch(
    params: ManageBatchParams
  ): Promise<TransactionResult & { returnData: `0x${string}`[] }> {
    // Transform object array into separate arrays for contract call
    const targets = params.calls.map((call) => call.target);
    const data = params.calls.map((call) => call.data);
    const values = params.calls.map((call) => call.value);

    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "manageBatch",
      args: [targets, data, values],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    const result = await this.waitForTransaction(hash);

    return {
      ...result,
      returnData: [], // Return data available in logs
    };
  }

  /**
   * Force manageBatch transaction onchain even if simulation fails
   * Useful for debugging - will execute the transaction and show the onchain error
   *
   * @param params Batch call parameters
   * @returns Transaction result with status (may be 'reverted')
   *
   * @example
   * ```typescript
   * const result = await client.manageBatchForce({
   *   calls: [
   *     { target: tokenAddress, data: approveCalldata, value: 0n },
   *     { target: routerAddress, data: swapCalldata, value: 0n }
   *   ],
   *   gasOptions: { gas: 800000n }
   * });
   * ```
   */
  async manageBatchForce(
    params: ManageBatchParams
  ): Promise<TransactionResult & { returnData: `0x${string}`[] }> {
    const targets = params.calls.map((call) => call.target);
    const data = params.calls.map((call) => call.data);
    const values = params.calls.map((call) => call.value);

    console.log("⚠️ FORCE MODE: Sending transaction without simulation");
    console.log("Safe Address:", this.safeAddress);
    console.log("Sender:", this.getAccount().address);
    console.log("Targets:", targets);
    console.log("Values:", values);
    console.log("Gas Options:", params.gasOptions);

    // Encode the function call manually
    const calldata = encodeFunctionData({
      abi: LEGION_SAFE_ABI,
      functionName: "manageBatch",
      args: [targets, data, values],
    });

    console.log("Encoded calldata length:", calldata.length);

    try {
      // Prepare transaction without simulation
      const request = await this.walletClient.prepareTransactionRequest({
        account: this.getAccount(),
        to: this.safeAddress,
        data: calldata,
        chain: this.walletClient.chain,
        gas: params.gasOptions?.gas,
        gasPrice: params.gasOptions?.gasPrice,
        maxFeePerGas: params.gasOptions?.maxFeePerGas,
        maxPriorityFeePerGas: params.gasOptions?.maxPriorityFeePerGas,
      } as any);

      console.log("📤 Sending transaction...");
      console.log("To:", request.to);
      console.log("Gas:", request.gas);

      // Send the transaction directly without simulation
      const hash = await this.walletClient.sendTransaction(request as any);

      console.log("✅ Transaction sent:", hash);
      console.log("🔗 View on explorer");
      console.log("⏳ Waiting for confirmation...");

      // Wait for the transaction receipt
      const receipt = await this.publicClient.waitForTransactionReceipt({
        hash,
        timeout: 120_000, // 2 minute timeout
      });

      console.log("\n📦 Receipt received");
      console.log("Status:", receipt.status);
      console.log("Block:", receipt.blockNumber);
      console.log("Gas used:", receipt.gasUsed);

      if (receipt.status === "reverted") {
        console.error("\n❌ Transaction REVERTED onchain!");
        await this.extractRevertReason(hash, receipt.blockNumber);
      } else {
        console.log("\n✅ Transaction SUCCEEDED onchain!");
      }

      return {
        hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed,
        status: receipt.status,
        returnData: [],
      };
    } catch (sendError: any) {
      console.error("\n❌ Failed to send transaction");
      console.error("Error:", sendError.message);
      console.error("Stack:", sendError.stack);
      throw sendError;
    }
  }

  /**
   * Extract revert reason from a failed transaction
   * @private
   */
  private async extractRevertReason(hash: `0x${string}`, blockNumber: bigint) {
    try {
      console.log("🔍 Extracting revert reason...");

      const tx = await this.publicClient.getTransaction({ hash });

      // Replay the transaction at the previous block to get the error
      await this.publicClient.call({
        account: tx.from,
        to: tx.to!,
        data: tx.input,
        blockNumber: blockNumber - 1n,
      });
    } catch (error: any) {
      console.error("\n=== REVERT REASON ===");
      console.error("Message:", error.message);
      console.error("Short Message:", error.shortMessage);

      const errorData = error.cause?.data || error.data;
      if (errorData) {
        const selector = errorData.slice(0, 10);
        console.error("\nError Selector:", selector);
        this.logKnownError(selector);

        // Try to decode with ABI
        try {
          const decoded = decodeErrorResult({
            abi: LEGION_SAFE_ABI,
            data: errorData,
          });
          console.error("Decoded Error:", decoded);
        } catch (decodeErr) {
          console.error("Could not decode with ABI");
        }
      }

      if (error.metaMessages) {
        console.error("\nMeta Messages:");
        error.metaMessages.forEach((msg: string) => console.error("  -", msg));
      }
    }
  }

  /**
   * Log known error selectors with descriptions
   * @private
   */
  private logKnownError(selector: string) {
    const knownErrors: Record<string, string> = {
      "0xa5fa8d2b":
        "SpenderNotWhitelisted() - The spender address is not whitelisted for approvals",
      "0x82b42900":
        "Unauthorized() - Caller is not authorized (not owner or operator)",
      "0xd47e0481": "CallNotAuthorized() - The function call is not authorized",
      "0x3f2c5891": "InvalidAddress() - An invalid address was provided",
      "0x750b219c": "InvalidAmount() - An invalid amount was provided",
      "0x5ff9a827": "CallFailed(bytes) - The external call failed",
      "0xc49eb42f": "WithdrawalFailed() - ETH withdrawal failed",
      "0xc1ab6dc1": "InvalidInput() - Invalid input parameters",
      "0x08c379a0": "Error(string) - Standard Solidity revert with message",
      "0x4e487b71": "Panic(uint256) - Solidity panic error",
    };

    if (knownErrors[selector]) {
      console.error("🔍 Decoded:", knownErrors[selector]);
    } else {
      console.error("❓ Unknown error selector");
      console.error(
        "🌐 Lookup at:",
        `https://openchain.xyz/signatures?query=${selector}`
      );
      console.error(
        "🌐 Or at:",
        `https://www.4byte.directory/signatures/?bytes4_signature=${selector}`
      );
    }
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
      functionName: "withdrawETH",
      args: [params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Withdraw all ETH from the vault to the owner (owner only)
   *
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async withdrawAllETH(gasOptions?: GasOptions): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllETH",
      args: [],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
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
      functionName: "withdrawERC20",
      args: [params.token, params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Withdraw all ERC20 tokens from the vault to the owner (owner only)
   *
   * @param token Token address
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async withdrawAllERC20(
    token: Address,
    gasOptions?: GasOptions
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllERC20",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
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
      functionName: "getETHBalance",
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
        functionName: "getTokenBalance",
        args: [token],
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: "decimals",
      }),
      this.publicClient.readContract({
        address: token,
        abi: ERC20_ABI,
        functionName: "symbol",
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
      functionName: "owner",
    });
  }

  /**
   * Get the vault's operator address
   */
  async getOperator(): Promise<Address> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "operator",
    });
  }

  /**
   * Transfer ownership to a new address (owner only)
   *
   * @param newOwner New owner address
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async transferOwnership(
    newOwner: Address,
    gasOptions?: GasOptions
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "transferOwnership",
      args: [newOwner],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Set a new operator address (owner only)
   *
   * @param newOperator New operator address
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async setOperator(
    newOperator: Address,
    gasOptions?: GasOptions
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setOperator",
      args: [newOperator],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  // ============================================
  // Spending Limit & Whitelist Methods
  // ============================================

  /**
   * Whitelist or remove a spender address for ERC20 approve operations (owner only)
   *
   * @param params Whitelist parameters
   * @returns Transaction result
   *
   * @example
   * ```typescript
   * await client.setSpenderWhitelist({
   *   spender: '0xRouterAddress',
   *   whitelisted: true,
   * });
   * ```
   */
  async setSpenderWhitelist(
    params: SetSpenderWhitelistParams
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setSpenderWhitelist",
      args: [params.spender, params.whitelisted],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Check if a spender is whitelisted
   *
   * @param spender Spender address
   * @returns Whether the spender is whitelisted
   */
  async isSpenderWhitelisted(spender: Address): Promise<boolean> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "whitelistedSpenders",
      args: [spender],
    });
  }

  /**
   * Add a token to the spending tracking list (owner only)
   *
   * @param token Token address (use 0x0 for native token)
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async addTrackedToken(
    token: Address,
    gasOptions?: GasOptions
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "addTrackedToken",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Remove a token from the spending tracking list (owner only)
   *
   * @param token Token address to remove
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async removeTrackedToken(
    token: Address,
    gasOptions?: GasOptions
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "removeTrackedToken",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Get the list of tracked tokens
   *
   * @returns Array of tracked token addresses
   */
  async getTrackedTokens(): Promise<Address[]> {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "getTrackedTokens",
    }) as Promise<Address[]>;
  }

  /**
   * Set spending limit for a token (owner only)
   *
   * @param params Spending limit parameters
   * @returns Transaction result
   *
   * @example
   * ```typescript
   * // Set 100 USDC per 6 hours (default window)
   * await client.setSpendingLimit({
   *   token: '0xUSDC_ADDRESS',
   *   limitPerWindow: 100_000000n, // 100 USDC (6 decimals)
   * });
   *
   * // Set 1 ETH per 1 hour (custom window)
   * await client.setSpendingLimit({
   *   token: '0x0000000000000000000000000000000000000000',
   *   limitPerWindow: parseEther('1'),
   *   windowDuration: 3600n, // 1 hour in seconds
   * });
   * ```
   */
  async setSpendingLimit(
    params: SetSpendingLimitParams
  ): Promise<TransactionResult> {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setSpendingLimit",
      args: [params.token, params.limitPerWindow, params.windowDuration || 0n],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...((params.gasOptions as any) || {}),
    });

    return this.waitForTransaction(hash);
  }

  /**
   * Get spending limit information for a token
   *
   * @param token Token address
   * @returns Spending limit info including remaining amount and window end time
   *
   * @example
   * ```typescript
   * const info = await client.getSpendingLimitInfo('0xUSDC_ADDRESS');
   * console.log(`Remaining: ${formatUnits(info.remaining, 6)} USDC`);
   * console.log(`Window ends at: ${new Date(Number(info.windowEndsAt) * 1000)}`);
   * ```
   */
  async getSpendingLimitInfo(token: Address): Promise<SpendingLimitInfo> {
    const [limitData, remainingData] = await Promise.all([
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: "spendingLimits",
        args: [token],
      }) as Promise<[bigint, bigint, bigint, bigint]>,
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: "getRemainingLimit",
        args: [token],
      }) as Promise<[bigint, bigint]>,
    ]);

    const [limitPerWindow, windowDuration, spent, lastWindowStart] = limitData;
    const [remaining, windowEndsAt] = remainingData;

    return {
      limitPerWindow,
      windowDuration,
      spent,
      lastWindowStart,
      remaining,
      windowEndsAt,
    };
  }
}
