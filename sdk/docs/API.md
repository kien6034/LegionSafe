# API Reference

## LegionSafeClient

Main client for interacting with LegionSafe contracts.

### Constructor

```typescript
new LegionSafeClient(config: LegionSafeConfig)
```

**Parameters:**
- `config.safeAddress` - Address of the deployed LegionSafe contract
- `config.walletClient` - Viem wallet client for signing transactions
- `config.publicClient` - Viem public client for reading state

### Methods

#### authorizeCall()

Authorize or revoke a function call.

```typescript
authorizeCall(params: AuthorizeCallParams): Promise<TransactionResult>
```

**Parameters:**
- `params.target` - Target contract address
- `params.selector` - 4-byte function selector
- `params.authorized` - Whether to authorize or revoke

**Returns:** Transaction result with hash, block number, gas used

---

#### isCallAuthorized()

Check if a function call is authorized.

```typescript
isCallAuthorized(target: Address, selector: `0x${string}`): Promise<boolean>
```

---

#### manage()

Execute an arbitrary call through the vault.

```typescript
manage(params: ManageCallParams): Promise<TransactionResult>
```

**Parameters:**
- `params.target` - Target contract address
- `params.data` - Encoded calldata
- `params.value` - Native token value (in wei)

---

#### withdrawETH()

Withdraw ETH from the vault (owner only).

```typescript
withdrawETH(params: WithdrawETHParams): Promise<TransactionResult>
```

---

#### withdrawAllETH()

Withdraw all ETH from the vault (owner only).

```typescript
withdrawAllETH(recipient: Address): Promise<TransactionResult>
```

---

#### withdrawERC20()

Withdraw ERC20 tokens from the vault (owner only).

```typescript
withdrawERC20(params: WithdrawERC20Params): Promise<TransactionResult>
```

---

#### withdrawAllERC20()

Withdraw all ERC20 tokens from the vault (owner only).

```typescript
withdrawAllERC20(token: Address, recipient: Address): Promise<TransactionResult>
```

---

#### getETHBalance()

Get the vault's native token balance.

```typescript
getETHBalance(): Promise<BalanceInfo>
```

**Returns:** Balance with raw value, formatted string, and decimals

---

#### getTokenBalance()

Get the vault's ERC20 token balance.

```typescript
getTokenBalance(token: Address): Promise<BalanceInfo>
```

**Returns:** Balance with raw value, formatted string, decimals, and symbol

---

#### getOwner()

Get the vault's owner address.

```typescript
getOwner(): Promise<Address>
```

---

#### getOperator()

Get the vault's operator address.

```typescript
getOperator(): Promise<Address>
```

---

#### transferOwnership()

Transfer ownership to a new address (owner only).

```typescript
transferOwnership(newOwner: Address): Promise<TransactionResult>
```

---

#### setOperator()

Set a new operator address (owner only).

```typescript
setOperator(newOperator: Address): Promise<TransactionResult>
```

---

## KyberSwapClient

Client for KyberSwap DEX aggregator integration.

### Constructor

```typescript
new KyberSwapClient(chainId: number)
```

**Parameters:**
- `chainId` - Chain ID (1=Ethereum, 56=BSC, etc.)

### Methods

#### getRoute()

Get the best swap route.

```typescript
getRoute(
  tokenIn: Address,
  tokenOut: Address,
  amountIn: string
): Promise<KyberSwapRoute>
```

---

#### buildSwap()

Build swap transaction calldata.

```typescript
buildSwap(
  route: KyberSwapRoute,
  sender: Address,
  recipient: Address,
  slippageTolerance?: number
): Promise<KyberSwapBuildRouteResponse>
```

---

#### getSwapCalldata()

Get swap calldata in one call (combines getRoute + buildSwap).

```typescript
getSwapCalldata(params: KyberSwapParams): Promise<{
  calldata: `0x${string}`;
  amountOut: string;
  routerAddress: Address;
}>
```

---

## Utility Functions

### getFunctionSelector()

Extract 4-byte function selector from calldata or signature.

```typescript
getFunctionSelector(input: string): `0x${string}`
```

**Examples:**
```typescript
getFunctionSelector('0x12345678...') // '0x12345678'
getFunctionSelector('transfer(address,uint256)') // '0xa9059cbb'
```

---

### isZeroAddress()

Check if an address is the zero address.

```typescript
isZeroAddress(address: Address): boolean
```

---

### isValidAddress()

Validate that a value is a valid Ethereum address.

```typescript
isValidAddress(value: string): value is Address
```

---

### formatHash()

Format a transaction hash for display with ellipsis.

```typescript
formatHash(hash: string, startChars?: number, endChars?: number): string
```

---

## Types

See [types.ts](../src/types.ts) for all exported TypeScript types and interfaces.

## Constants

- `CHAIN_IDS` - Common chain IDs
- `NATIVE_TOKEN_ADDRESS` - Native token placeholder address
- `ZERO_ADDRESS` - Zero address constant
- `KYBERSWAP_ROUTERS` - KyberSwap router addresses by chain
- `KYBERSWAP_SELECTORS` - Common KyberSwap function selectors
