// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice BSC mainnet addresses for fork testing
library BSC {
    // Network
    uint256 constant CHAIN_ID = 56;
    string constant RPC_URL = "https://bsc-dataseed1.binance.org";

    // Tokens
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

    // KyberSwap
    address constant KYBER_ROUTER = 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5; // MetaAggregationRouterV2

    // Whales for testing (addresses with large balances)
    address constant WBNB_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Binance 8
    address constant USDT_WHALE = 0x8894E0a0c962CB723c1976a4421c95949bE2D4E3; // Binance 14
}
