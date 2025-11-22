# Makefile for LegionSafe

# Default values
BSC_RPC ?= https://bsc-dataseed1.binance.org

# ============================================================================
# Build & Test Commands
# ============================================================================

.PHONY: build
build:
	@echo "Building contracts..."
	forge build

.PHONY: test
test:
	@echo "Running all tests..."
	forge test

.PHONY: test-v
test-v:
	@echo "Running tests with verbose output..."
	forge test -vvv

.PHONY: test-gas
test-gas:
	@echo "Running tests with gas report..."
	forge test --gas-report

.PHONY: coverage
coverage:
	@echo "Running coverage..."
	forge coverage

.PHONY: fmt
fmt:
	@echo "Formatting code..."
	forge fmt

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	forge clean

# ============================================================================
# Fork Testing Commands
# ============================================================================

.PHONY: test-fork-kyber
test-fork-kyber:
	@echo "Running KyberSwap fork tests on BSC..."
	forge test --match-contract LegionSafe_KyberSwap_BSC_Test --fork-url $(BSC_RPC) -vvv

.PHONY: test-fork-kyber-setup
test-fork-kyber-setup:
	@echo "Running fork setup test..."
	forge test --match-test testForkSetup --fork-url $(BSC_RPC) -vvv

.PHONY: test-fork-kyber-swap
test-fork-kyber-swap:
	@echo "Running BNB to USDT swap test..."
	forge test --match-test testSwapBNBToUSDT --fork-url $(BSC_RPC) -vvvv

.PHONY: test-fork-kyber-auth
test-fork-kyber-auth:
	@echo "Running authorization tests..."
	forge test --match-test "testSwapBNBToUSDT_RevertWhen" --fork-url $(BSC_RPC) -vvv

.PHONY: test-fork-api
test-fork-api:
	@echo "Running API-based fork tests..."
	forge test --match-contract LegionSafe_KyberSwap_API_Test --fork-url $(BSC_RPC) -vvvv

.PHONY: test-fork-all
test-fork-all:
	@echo "Running all fork tests..."
	forge test --match-path "test/fork/**/*.sol" --fork-url $(BSC_RPC) -vvv

# ============================================================================
# Help
# ============================================================================

.PHONY: help
help:
	@echo "LegionSafe Makefile Commands"
	@echo ""
	@echo "Build & Test:"
	@echo "  make build              - Build contracts"
	@echo "  make test               - Run all tests"
	@echo "  make test-v             - Run tests with verbose output"
	@echo "  make test-gas           - Run tests with gas report"
	@echo "  make coverage           - Run coverage report"
	@echo "  make fmt                - Format code"
	@echo "  make clean              - Clean build artifacts"
	@echo ""
	@echo "Fork Testing:"
	@echo "  make test-fork-kyber    - Run all KyberSwap BSC fork tests"
	@echo "  make test-fork-kyber-setup - Run fork setup test only"
	@echo "  make test-fork-kyber-swap - Run swap test with verbose output"
	@echo "  make test-fork-kyber-auth - Run authorization tests"
	@echo "  make test-fork-api      - Run API-based fork tests"
	@echo "  make test-fork-all      - Run all fork tests"
	@echo ""
	@echo "Environment Variables:"
	@echo "  BSC_RPC                 - BSC RPC URL (default: https://bsc-dataseed1.binance.org)"
	@echo ""
	@echo "Examples:"
	@echo "  make test-fork-kyber"
	@echo "  BSC_RPC=https://your-rpc-url.com make test-fork-all"

.PHONY: help-fork
help-fork:
	@echo "Fork Testing Commands:"
	@echo "  make test-fork-kyber       - Run all KyberSwap BSC fork tests"
	@echo "  make test-fork-kyber-setup - Run fork setup test only"
	@echo "  make test-fork-kyber-swap  - Run swap test with verbose output"
	@echo "  make test-fork-kyber-auth  - Run authorization tests"
	@echo "  make test-fork-api         - Run API-based fork tests"
	@echo "  make test-fork-all         - Run all fork tests"
	@echo ""
	@echo "Environment Variables:"
	@echo "  BSC_RPC                    - BSC RPC URL (default: https://bsc-dataseed1.binance.org)"


# Debug manageBatch with specific data
.PHONY: test-debug-managebatch
test-debug-managebatch:
	@echo "Running manageBatch debug test on BSC fork..."
	forge test --match-contract LegionSafe_ManageBatch_Debug --match-test test_manageBatch_debug --fork-url $(BSC_RPC) -vvvv

.PHONY: test-debug-managebatch-unlimited
test-debug-managebatch-unlimited:
	@echo "Running manageBatch debug test with unlimited gas on BSC fork..."
	forge test --match-contract LegionSafe_ManageBatch_Debug --match-test test_manageBatch_unlimited_gas --fork-url $(BSC_RPC) -vvvv

