# Fork Tests

Integration tests that fork live networks to test LegionSafe with real DeFi protocols.

## Overview

Fork tests use Foundry's forking feature to:
- Test against live protocol contracts
- Verify real-world integrations
- Validate swap/trade execution
- Test with actual on-chain liquidity

## Running Fork Tests

### All Fork Tests
```bash
make test-fork-all
```

### KyberSwap Integration (BSC)
```bash
make test-fork-kyber
```

### Specific Test Types
```bash
make test-fork-kyber-setup    # Setup tests only
make test-fork-kyber-swap     # Swap test with verbose output
make test-fork-kyber-auth     # Authorization tests
make test-fork-api            # API-based tests
```

### Manual Execution
```bash
forge test --match-contract LegionSafe_KyberSwap_BSC_Test \
  --fork-url https://bsc-dataseed1.binance.org \
  -vvv
```

### Using Custom RPC
```bash
BSC_RPC=https://your-rpc-url.com make test-fork-kyber
```

## Test Structure

```
test/fork/
├── addresses/
│   └── BSC.sol                          # BSC mainnet addresses
├── helpers/
│   └── KyberSwapHelper.sol              # Helper for building calldata
├── interfaces/
│   └── IKyberSwapRouter.sol             # KyberSwap router interface
├── ForkTestBase.sol                     # Base contract for fork tests
├── LegionSafe_KyberSwap_BSC.t.sol      # Main BSC + KyberSwap tests
├── LegionSafe_KyberSwap_API.t.sol      # API-based testing template
└── README.md                            # This file
```

## Test Cases

### LegionSafe_KyberSwap_BSC_Test

**testForkSetup**
- Verifies fork is created correctly
- Checks LegionSafe is deployed and funded
- Confirms router authorization

**testSwapBNBToUSDT** (Skipped - requires API data)
- Template for swapping 1 BNB → USDT via KyberSwap
- Shows complete swap flow
- Requires real API route data to work

**testSwapBNBToUSDT_RevertWhen_NotOperator**
- Tests access control
- Ensures only operator can execute swaps
- Verifies `Unauthorized` error

**testSwapBNBToUSDT_RevertWhen_RouterNotAuthorized**
- Tests function authorization
- Verifies `CallNotAuthorized` error when function not authorized

### LegionSafe_KyberSwap_API_Test

**testSwapWithRealAPIData** (Template)
- Demonstrates how to use real KyberSwap API data
- Includes step-by-step instructions
- Skipped by default until API data is provided

**testSwapWithKnownAPIResponse** (Template)
- Shows how to test with specific API responses
- Useful for regression testing

## Using Real API Data

The KyberSwap router requires real route data from their aggregator API. Empty executor data won't work.

### Steps to Test with Real API:

1. **Get Route Data:**
```bash
curl "https://aggregator-api.kyberswap.com/bsc/api/v1/routes?tokenIn=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&tokenOut=0x55d398326f99059fF775485246999027B3197955&amountIn=1000000000000000000"
```

2. **Build Transaction:**
```bash
curl -X POST "https://aggregator-api.kyberswap.com/bsc/api/v1/route/build" \
  -H "Content-Type: application/json" \
  -d '{
    "routeSummary": <ROUTE_FROM_STEP_1>,
    "sender": "<LEGION_SAFE_ADDRESS>",
    "recipient": "<LEGION_SAFE_ADDRESS>"
  }'
```

3. **Extract Calldata:**
   - Copy the `data` field from the API response

4. **Update Test:**
   - Open `test/fork/LegionSafe_KyberSwap_API.t.sol`
   - Paste the calldata into `testSwapWithRealAPIData`
   - Remove the `vm.skip(true)` line

5. **Run Test:**
```bash
make test-fork-api
```

## Adding New Fork Tests

### 1. Add Network Addresses

Create `test/fork/addresses/NetworkName.sol`:
```solidity
library NetworkName {
    uint256 constant CHAIN_ID = 1;
    string constant RPC_URL = "https://...";

    address constant TOKEN_A = 0x...;
    address constant DEX_ROUTER = 0x...;
}
```

### 2. Create Protocol Interface

Create `test/fork/interfaces/IProtocol.sol`:
```solidity
interface IProtocol {
    function swap(...) external returns (uint256);
}
```

### 3. Create Test File

Create `test/fork/LegionSafe_Protocol_Network.t.sol`:
```solidity
contract LegionSafe_Protocol_Network_Test is ForkTestBase {
    function setUp() public {
        createAndSelectFork(NetworkName.RPC_URL);
        // ... setup
    }

    function testSwap() public {
        // ... test
    }
}
```

### 4. Add Makefile Command

Update `Makefile`:
```makefile
.PHONY: test-fork-protocol
test-fork-protocol:
	forge test --match-contract LegionSafe_Protocol_Network_Test \
	  --fork-url $(NETWORK_RPC) -vvv
```

## Best Practices

1. **Label Addresses:** Always label addresses in setUp for better trace output
2. **Use Helpers:** Create helper libraries for building protocol-specific calldata
3. **Test Authorization:** Always test both authorized and unauthorized access
4. **Document API Requirements:** Note when tests need real API data
5. **Skip Expensive Tests:** Use `vm.skip(true)` for tests requiring external data
6. **Test Reverts:** Verify error messages and custom errors

## Troubleshooting

### Fork Creation Fails
- Check RPC URL is accessible
- Verify RPC supports archive data if needed
- Try a different RPC endpoint

### Test Reverts with "CallFailed"
- Check if protocol requires real API route data
- Verify target contract is authorized
- Ensure function selector is correct

### Slow Tests
- Use a paid/private RPC for faster responses
- Cache fork snapshots when possible
- Run specific tests instead of all fork tests

## Resources

- [Foundry Fork Testing Guide](https://book.getfoundry.sh/forge/fork-testing)
- [KyberSwap Aggregator API](https://docs.kyberswap.com/kyberswap-solutions/kyberswap-aggregator/aggregator-api-specification)
- [BSC RPC Endpoints](https://docs.bnbchain.org/docs/rpc)

## Notes

- Fork tests require RPC access to the network
- Tests may be slower than unit tests
- Use public RPCs for development, paid RPCs for CI/CD
- Some tests may fail if market prices change significantly
- Always verify contracts on block explorers before testing
