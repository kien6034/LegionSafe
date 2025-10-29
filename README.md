# LegionSafe

A secure vault smart contract for managing crypto meme trading automation with role-based access control. Inspired by yo.xyz's vault management pattern.

## Overview

LegionSafe is a Solidity smart contract that provides:

- **Role-Based Access Control**: Distinct roles for Owner and Operator
- **Operator Management**: Operators can execute authorized trades through a `manage()` function
- **Owner Withdrawals**: Owners have exclusive rights to withdraw funds (ETH and ERC20 tokens)
- **Authorization System**: Function-level authorization for target contracts
- **Reentrancy Protection**: Built-in protection against reentrancy attacks

## Architecture

### Roles

1. **Owner**: Can withdraw funds, authorize function calls, transfer ownership, and change operators
2. **Operator**: Can execute authorized trades through the `manage()` function

### Key Features

- **Authorization System**: Owners can authorize specific function signatures on target contracts
- **Flexible Management**: Operators can execute arbitrary calls to authorized contracts
- **Safe Withdrawals**: Owner-only withdrawal functions for both ETH and ERC20 tokens
- **Event Logging**: Comprehensive events for all major operations
- **Security**: Uses OpenZeppelin's ReentrancyGuard and SafeERC20

## Installation

This project uses Foundry. Install dependencies:

```bash
forge install
```

## Usage

### Build

```bash
forge build
```

### Test

Run all tests:
```bash
forge test
```

Run tests with verbosity:
```bash
forge test -vvv
```

Run specific test:
```bash
forge test --match-test testFunctionName
```

### Gas Report

```bash
forge test --gas-report
```

### Format

```bash
forge fmt
```

### Deploy

#### Local Deployment (for testing)

```bash
forge script script/Deploy.s.sol:DeployLegionSafeLocal --rpc-url http://localhost:8545 --broadcast
```

#### Production Deployment

Create a `.env` file:
```
OWNER_ADDRESS=0x...
OPERATOR_ADDRESS=0x...
PRIVATE_KEY=0x...
RPC_URL=https://...
ETHERSCAN_API_KEY=...
```

Deploy:
```bash
source .env
forge script script/Deploy.s.sol:DeployLegionSafe --rpc-url $RPC_URL --broadcast --verify
```

## Contract API

### Core Functions

#### Authorization (Owner Only)

- `setCallAuthorization(address target, bytes4 selector, bool authorized)`: Authorize/revoke function calls
- `transferOwnership(address newOwner)`: Transfer contract ownership
- `setOperator(address newOperator)`: Change the operator address

#### Management (Operator Only)

- `manage(address target, bytes calldata data, uint256 value)`: Execute authorized calls to external contracts

#### Withdrawals (Owner Only)

- `withdrawETH(address payable to, uint256 amount)`: Withdraw specific amount of ETH
- `withdrawAllETH(address payable to)`: Withdraw all ETH
- `withdrawERC20(address token, address to, uint256 amount)`: Withdraw specific amount of tokens
- `withdrawAllERC20(address token, address to)`: Withdraw all tokens

#### View Functions

- `getETHBalance()`: Get contract's ETH balance
- `getTokenBalance(address token)`: Get contract's token balance
- `authorizedCalls(address target, bytes4 selector)`: Check if a call is authorized

## Example Usage

### Authorizing a DEX Swap

```solidity
// Owner authorizes the swap function on a DEX
bytes4 swapSelector = bytes4(keccak256("swap(address,address,uint256,uint256)"));
vault.setCallAuthorization(dexAddress, swapSelector, true);
```

### Executing a Trade

```solidity
// Operator executes a swap
bytes memory data = abi.encodeWithSelector(
    swapSelector,
    tokenIn,
    tokenOut,
    amountIn,
    minAmountOut
);
vault.manage(dexAddress, data, 0);
```

### Withdrawing Profits

```solidity
// Owner withdraws tokens
vault.withdrawERC20(tokenAddress, recipientAddress, amount);
```

## Security Considerations

- All sensitive functions use role-based access control
- Reentrancy protection on manage() and withdrawal functions
- Authorization checks validate both caller and target function
- Uses OpenZeppelin's SafeERC20 for safe token transfers
- Comprehensive event logging for transparency

## Testing

The test suite includes:

- Unit tests for all core functionality
- Authorization boundary tests
- Integration tests with mock DEX contracts
- Reentrancy protection tests
- Edge case coverage

Test coverage: 38 tests covering deployment, ownership, operator management, authorization, manage function, withdrawals, and integration scenarios.

## Gas Report

Key operations gas costs:
- Deployment: ~1,838,686 gas
- manage(): ~58,321 gas (average)
- withdrawETH(): ~35,319 gas (average)
- withdrawERC20(): ~40,078 gas (average)
- setCallAuthorization(): ~44,052 gas (average)

## License

MIT

## Foundry Documentation

For more information on Foundry:
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Documentation](https://github.com/foundry-rs/foundry)
