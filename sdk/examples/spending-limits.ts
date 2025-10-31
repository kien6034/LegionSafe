/**
 * Example: Managing Spending Limits and Whitelisted Approvals
 *
 * This example demonstrates how to:
 * 1. Whitelist spenders (e.g., DEX routers)
 * 2. Set up token tracking
 * 3. Configure spending limits with custom windows
 * 4. Check remaining spending limits
 */

import { createPublicClient, createWalletClient, http, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { baseSepolia } from "viem/chains";
import { LegionSafeClient } from "../src/index.js";

// Configuration
const RPC_URL = process.env.RPC_URL || "https://sepolia.base.org";
const PRIVATE_KEY = process.env.PRIVATE_KEY as `0x${string}`;
const SAFE_ADDRESS = process.env.LEGION_SAFE_ADDRESS as `0x${string}`;

// Token addresses (example)
const USDC_ADDRESS = "0x..." as `0x${string}`;
const WETH_ADDRESS = "0x..." as `0x${string}`;
const UNISWAP_ROUTER = "0x..." as `0x${string}`;

async function main() {
  // Setup clients
  const account = privateKeyToAccount(PRIVATE_KEY);

  const publicClient = createPublicClient({
    chain: baseSepolia,
    transport: http(RPC_URL),
  });

  const walletClient = createWalletClient({
    account,
    chain: baseSepolia,
    transport: http(RPC_URL),
  });

  const safe = new LegionSafeClient({
    safeAddress: SAFE_ADDRESS,
    walletClient,
    publicClient,
  });

  console.log("🔧 Setting up spending limits and whitelists...\n");

  // ============================================
  // Step 1: Whitelist the router for approvals
  // ============================================
  console.log("1️⃣  Whitelisting Uniswap router for approvals...");
  const whitelistTx = await safe.setSpenderWhitelist({
    spender: UNISWAP_ROUTER,
    whitelisted: true,
  });
  console.log(`   ✅ Whitelisted! Hash: ${whitelistTx.hash}\n`);

  // Check if whitelisted
  const isWhitelisted = await safe.isSpenderWhitelisted(UNISWAP_ROUTER);
  console.log(`   ℹ️  Router whitelisted: ${isWhitelisted}\n`);

  // ============================================
  // Step 2: Track tokens for spending limits
  // ============================================
  console.log("2️⃣  Adding tokens to tracking list...");

  // Track USDC
  const addUsdcTx = await safe.addTrackedToken(USDC_ADDRESS);
  console.log(`   ✅ Added USDC tracking! Hash: ${addUsdcTx.hash}`);

  // Track native ETH (use zero address)
  const addEthTx = await safe.addTrackedToken(
    "0x0000000000000000000000000000000000000000"
  );
  console.log(`   ✅ Added ETH tracking! Hash: ${addEthTx.hash}\n`);

  // Get tracked tokens
  const trackedTokens = await safe.getTrackedTokens();
  console.log(`   ℹ️  Tracked tokens: ${trackedTokens.length} total\n`);

  // ============================================
  // Step 3: Set spending limits
  // ============================================
  console.log("3️⃣  Setting spending limits...");

  // Set USDC limit: 1000 USDC per 6 hours (default window)
  const usdcLimitTx = await safe.setSpendingLimit({
    token: USDC_ADDRESS,
    limitPerWindow: 1000_000000n, // 1000 USDC (6 decimals)
  });
  console.log(`   ✅ Set USDC limit (1000 per 6h)! Hash: ${usdcLimitTx.hash}`);

  // Set ETH limit: 0.5 ETH per 1 hour (custom window)
  const ethLimitTx = await safe.setSpendingLimit({
    token: "0x0000000000000000000000000000000000000000",
    limitPerWindow: parseEther("0.5"),
    windowDuration: 3600n, // 1 hour in seconds
  });
  console.log(
    `   ✅ Set ETH limit (0.5 ETH per 1h)! Hash: ${ethLimitTx.hash}\n`
  );

  // ============================================
  // Step 4: Check spending limit info
  // ============================================
  console.log("4️⃣  Checking spending limit information...\n");

  // Get USDC limit info
  const usdcInfo = await safe.getSpendingLimitInfo(USDC_ADDRESS);
  console.log("   📊 USDC Spending Limit:");
  console.log(`      Limit per window: ${usdcInfo.limitPerWindow} (1000 USDC)`);
  console.log(
    `      Window duration: ${usdcInfo.windowDuration}s (${
      Number(usdcInfo.windowDuration) / 3600
    }h)`
  );
  console.log(`      Spent so far: ${usdcInfo.spent}`);
  console.log(`      Remaining: ${usdcInfo.remaining}`);
  console.log(
    `      Window ends at: ${new Date(
      Number(usdcInfo.windowEndsAt) * 1000
    ).toLocaleString()}\n`
  );

  // Get ETH limit info
  const ethInfo = await safe.getSpendingLimitInfo(
    "0x0000000000000000000000000000000000000000"
  );
  console.log("   📊 ETH Spending Limit:");
  console.log(`      Limit per window: ${ethInfo.limitPerWindow} (0.5 ETH)`);
  console.log(
    `      Window duration: ${ethInfo.windowDuration}s (${
      Number(ethInfo.windowDuration) / 3600
    }h)`
  );
  console.log(`      Spent so far: ${ethInfo.spent}`);
  console.log(`      Remaining: ${ethInfo.remaining}`);
  console.log(
    `      Window ends at: ${new Date(
      Number(ethInfo.windowEndsAt) * 1000
    ).toLocaleString()}\n`
  );

  // ============================================
  // Step 5: Remove token from tracking (optional)
  // ============================================
  console.log("5️⃣  Removing WETH from tracking (example)...");
  try {
    const removeTx = await safe.removeTrackedToken(WETH_ADDRESS);
    console.log(`   ✅ Removed WETH! Hash: ${removeTx.hash}\n`);
  } catch (error) {
    console.log(`   ℹ️  WETH not tracked (expected)\n`);
  }

  console.log("✨ Done! Spending limits configured successfully.");
}

main().catch(console.error);
