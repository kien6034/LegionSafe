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
    name: "manageBatch",
    inputs: [
      { name: "targets", type: "address[]" },
      { name: "data", type: "bytes[]" },
      { name: "values", type: "uint256[]" }
    ],
    outputs: [{ name: "", type: "bytes[]" }],
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
    inputs: [{ name: "amount", type: "uint256" }],
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
    inputs: [{ name: "token", type: "address" }],
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
    type: "function",
    name: "setSpenderWhitelist",
    inputs: [
      { name: "spender", type: "address" },
      { name: "whitelisted", type: "bool" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "whitelistedSpenders",
    inputs: [{ name: "spender", type: "address" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "addTrackedToken",
    inputs: [{ name: "token", type: "address" }],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "removeTrackedToken",
    inputs: [{ name: "token", type: "address" }],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "getTrackedTokens",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "setSpendingLimit",
    inputs: [
      { name: "token", type: "address" },
      { name: "limitPerWindow", type: "uint256" },
      { name: "windowDuration", type: "uint256" }
    ],
    outputs: [],
    stateMutability: "nonpayable"
  },
  {
    type: "function",
    name: "getRemainingLimit",
    inputs: [{ name: "token", type: "address" }],
    outputs: [
      { name: "remaining", type: "uint256" },
      { name: "windowEndsAt", type: "uint256" }
    ],
    stateMutability: "view"
  },
  {
    type: "function",
    name: "spendingLimits",
    inputs: [{ name: "token", type: "address" }],
    outputs: [
      { name: "limitPerWindow", type: "uint256" },
      { name: "windowDuration", type: "uint256" },
      { name: "spent", type: "uint256" },
      { name: "lastWindowStart", type: "uint256" }
    ],
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
    type: "event",
    name: "ManagedBatch",
    inputs: [
      { name: "targets", type: "address[]", indexed: false },
      { name: "data", type: "bytes[]", indexed: false },
      { name: "values", type: "uint256[]", indexed: false }
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
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
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
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
    });
    const result = await this.waitForTransaction(hash);
    return {
      ...result,
      returnData: "0x"
      // Return data is available in logs
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
  async manageBatch(params) {
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
      ...params.gasOptions || {}
    });
    const result = await this.waitForTransaction(hash);
    return {
      ...result,
      returnData: []
      // Return data available in logs
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
  async manageBatchForce(params) {
    const targets = params.calls.map((call) => call.target);
    const data = params.calls.map((call) => call.data);
    const values = params.calls.map((call) => call.value);
    console.log("\u26A0\uFE0F FORCE MODE: Sending transaction without simulation");
    console.log("Safe Address:", this.safeAddress);
    console.log("Sender:", this.getAccount().address);
    console.log("Targets:", targets);
    console.log("Values:", values);
    console.log("Gas Options:", params.gasOptions);
    const calldata = viem.encodeFunctionData({
      abi: LEGION_SAFE_ABI,
      functionName: "manageBatch",
      args: [targets, data, values]
    });
    console.log("Encoded calldata length:", calldata.length);
    try {
      const request = await this.walletClient.prepareTransactionRequest({
        account: this.getAccount(),
        to: this.safeAddress,
        data: calldata,
        chain: this.walletClient.chain,
        gas: params.gasOptions?.gas,
        gasPrice: params.gasOptions?.gasPrice,
        maxFeePerGas: params.gasOptions?.maxFeePerGas,
        maxPriorityFeePerGas: params.gasOptions?.maxPriorityFeePerGas
      });
      console.log("\u{1F4E4} Sending transaction...");
      console.log("To:", request.to);
      console.log("Gas:", request.gas);
      const hash = await this.walletClient.sendTransaction(request);
      console.log("\u2705 Transaction sent:", hash);
      console.log("\u{1F517} View on explorer");
      console.log("\u23F3 Waiting for confirmation...");
      const receipt = await this.publicClient.waitForTransactionReceipt({
        hash,
        timeout: 12e4
        // 2 minute timeout
      });
      console.log("\n\u{1F4E6} Receipt received");
      console.log("Status:", receipt.status);
      console.log("Block:", receipt.blockNumber);
      console.log("Gas used:", receipt.gasUsed);
      if (receipt.status === "reverted") {
        console.error("\n\u274C Transaction REVERTED onchain!");
        await this.extractRevertReason(hash, receipt.blockNumber);
      } else {
        console.log("\n\u2705 Transaction SUCCEEDED onchain!");
      }
      return {
        hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed,
        status: receipt.status,
        returnData: []
      };
    } catch (sendError) {
      console.error("\n\u274C Failed to send transaction");
      console.error("Error:", sendError.message);
      console.error("Stack:", sendError.stack);
      throw sendError;
    }
  }
  /**
   * Extract revert reason from a failed transaction
   * @private
   */
  async extractRevertReason(hash, blockNumber) {
    try {
      console.log("\u{1F50D} Extracting revert reason...");
      const tx = await this.publicClient.getTransaction({ hash });
      await this.publicClient.call({
        account: tx.from,
        to: tx.to,
        data: tx.input,
        blockNumber: blockNumber - 1n
      });
    } catch (error) {
      console.error("\n=== REVERT REASON ===");
      console.error("Message:", error.message);
      console.error("Short Message:", error.shortMessage);
      const errorData = error.cause?.data || error.data;
      if (errorData) {
        const selector = errorData.slice(0, 10);
        console.error("\nError Selector:", selector);
        this.logKnownError(selector);
        try {
          const decoded = viem.decodeErrorResult({
            abi: LEGION_SAFE_ABI,
            data: errorData
          });
          console.error("Decoded Error:", decoded);
        } catch (decodeErr) {
          console.error("Could not decode with ABI");
        }
      }
      if (error.metaMessages) {
        console.error("\nMeta Messages:");
        error.metaMessages.forEach((msg) => console.error("  -", msg));
      }
    }
  }
  /**
   * Log known error selectors with descriptions
   * @private
   */
  logKnownError(selector) {
    const knownErrors = {
      "0xa5fa8d2b": "SpenderNotWhitelisted() - The spender address is not whitelisted for approvals",
      "0x82b42900": "Unauthorized() - Caller is not authorized (not owner or operator)",
      "0xd47e0481": "CallNotAuthorized() - The function call is not authorized",
      "0x3f2c5891": "InvalidAddress() - An invalid address was provided",
      "0x750b219c": "InvalidAmount() - An invalid amount was provided",
      "0x5ff9a827": "CallFailed(bytes) - The external call failed",
      "0xc49eb42f": "WithdrawalFailed() - ETH withdrawal failed",
      "0xc1ab6dc1": "InvalidInput() - Invalid input parameters",
      "0x08c379a0": "Error(string) - Standard Solidity revert with message",
      "0x4e487b71": "Panic(uint256) - Solidity panic error"
    };
    if (knownErrors[selector]) {
      console.error("\u{1F50D} Decoded:", knownErrors[selector]);
    } else {
      console.error("\u2753 Unknown error selector");
      console.error(
        "\u{1F310} Lookup at:",
        `https://openchain.xyz/signatures?query=${selector}`
      );
      console.error(
        "\u{1F310} Or at:",
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
  async withdrawETH(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawETH",
      args: [params.amount],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Withdraw all ETH from the vault to the owner (owner only)
   *
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async withdrawAllETH(gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllETH",
      args: [],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
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
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
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
  async withdrawAllERC20(token, gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "withdrawAllERC20",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
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
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async transferOwnership(newOwner, gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "transferOwnership",
      args: [newOwner],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
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
  async setOperator(newOperator, gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setOperator",
      args: [newOperator],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
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
  async setSpenderWhitelist(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setSpenderWhitelist",
      args: [params.spender, params.whitelisted],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Check if a spender is whitelisted
   *
   * @param spender Spender address
   * @returns Whether the spender is whitelisted
   */
  async isSpenderWhitelisted(spender) {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "whitelistedSpenders",
      args: [spender]
    });
  }
  /**
   * Add a token to the spending tracking list (owner only)
   *
   * @param token Token address (use 0x0 for native token)
   * @param gasOptions Optional gas configuration
   * @returns Transaction result
   */
  async addTrackedToken(token, gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "addTrackedToken",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
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
  async removeTrackedToken(token, gasOptions) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "removeTrackedToken",
      args: [token],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...gasOptions || {}
    });
    return this.waitForTransaction(hash);
  }
  /**
   * Get the list of tracked tokens
   *
   * @returns Array of tracked token addresses
   */
  async getTrackedTokens() {
    return this.publicClient.readContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "getTrackedTokens"
    });
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
  async setSpendingLimit(params) {
    const hash = await this.walletClient.writeContract({
      address: this.safeAddress,
      abi: LEGION_SAFE_ABI,
      functionName: "setSpendingLimit",
      args: [params.token, params.limitPerWindow, params.windowDuration || 0n],
      account: this.getAccount(),
      chain: this.walletClient.chain,
      ...params.gasOptions || {}
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
  async getSpendingLimitInfo(token) {
    const [limitData, remainingData] = await Promise.all([
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: "spendingLimits",
        args: [token]
      }),
      this.publicClient.readContract({
        address: this.safeAddress,
        abi: LEGION_SAFE_ABI,
        functionName: "getRemainingLimit",
        args: [token]
      })
    ]);
    const [limitPerWindow, windowDuration, spent, lastWindowStart] = limitData;
    const [remaining, windowEndsAt] = remainingData;
    return {
      limitPerWindow,
      windowDuration,
      spent,
      lastWindowStart,
      remaining,
      windowEndsAt
    };
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