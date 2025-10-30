# LegionSafe UUPS Upgradeability and Ownable2Step Design

**Date:** 2025-10-30
**Status:** Approved for Implementation

## Overview

This design adds UUPS (Universal Upgradeable Proxy Standard) upgradeability and two-step ownership transfer to the LegionSafe contract. The implementation uses OpenZeppelin's battle-tested patterns for security and maintainability.

## Objectives

1. Make LegionSafe upgradeable using UUPS proxy pattern
2. Replace custom ownership transfer with OpenZeppelin's Ownable2Step
3. Maintain all existing functionality and security guarantees
4. Keep operator role transfer as simple one-step process

## Architecture

### Inheritance Chain

```
LegionSafe
  ├─ Initializable
  ├─ Ownable2StepUpgradeable (includes OwnableUpgradeable)
  ├─ UUPSUpgradeable
  └─ ReentrancyGuardUpgradeable
```

### OpenZeppelin Dependencies

- **Ownable2StepUpgradeable**: Two-step ownership transfer (transferOwnership → acceptOwnership)
- **UUPSUpgradeable**: Upgrade mechanism controlled by owner
- **Initializable**: Replaces constructor for proxy compatibility
- **ReentrancyGuardUpgradeable**: Upgradeable reentrancy protection

### Storage Layout

```solidity
// From OwnableUpgradeable
address private _owner;

// From ReentrancyGuardUpgradeable
uint256 private _status;

// LegionSafe state
address public operator;
mapping(address => mapping(bytes4 => bool)) public authorizedCalls;

// No storage gaps (per design decision)
```

## Key Changes

### 1. Initialization Pattern

**Before (Constructor):**
```solidity
constructor(address _owner, address _operator) {
    owner = _owner;
    operator = _operator;
}
```

**After (Initializer):**
```solidity
function initialize(address _operator) public initializer {
    __Ownable_init(msg.sender); // or pass initial owner
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();

    operator = _operator;
}
```

### 2. Ownership Functions

**New Functions from Ownable2Step:**
- `transferOwnership(address newOwner)` - Starts ownership transfer
- `acceptOwnership()` - New owner accepts ownership
- `pendingOwner()` - View function for pending owner

**New Event:**
- `OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)`

**Operator Functions (unchanged):**
- `setOperator(address newOperator)` - Direct one-step transfer

### 3. Upgrade Authorization

```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
```

Only the owner can authorize upgrades. Empty function body because access control is handled by `onlyOwner` modifier.

## Deployment Strategy

### Two-Contract Deployment

```solidity
// 1. Deploy implementation
LegionSafe implementation = new LegionSafe();

// 2. Prepare initialization data
bytes memory initData = abi.encodeWithSelector(
    LegionSafe.initialize.selector,
    operatorAddress
);

// 3. Deploy proxy
ERC1967Proxy proxy = new ERC1967Proxy(
    address(implementation),
    initData
);

// 4. Cast proxy to interface
LegionSafe vault = LegionSafe(address(proxy));
```

Users interact with the **proxy address**, not the implementation address.

### Upgrade Process

```solidity
// 1. Deploy new implementation
LegionSafe implementationV2 = new LegionSafe();

// 2. Owner calls upgradeToAndCall on proxy
vault.upgradeToAndCall(
    address(implementationV2),
    "" // empty if no initialization needed
);
```

## Migration Strategy

### For Existing Deployments

**Option 1: Fresh Deployment (Recommended)**
- Deploy new UUPS version with proxy
- Transfer authorizations to new contract
- Migrate funds manually
- Update operator scripts to use new address

**Option 2: Parallel Deployment**
- Keep existing contracts running
- Deploy UUPS version for new vaults
- Gradually migrate over time

### For New Deployments

Always use proxy pattern via updated deployment scripts.

## Testing Requirements

### Updated Existing Tests

1. Modify `setUp()` to deploy via proxy pattern
2. Update all test assertions to use proxy address
3. Verify all existing functionality works through proxy

### New Test Coverage

1. **Initialization**
   - Test initialize() can only be called once
   - Test correct owner/operator setup
   - Test re-initialization fails

2. **Upgradeability**
   - Deploy V2 implementation
   - Upgrade via owner
   - Verify state preserved after upgrade
   - Test unauthorized upgrade fails

3. **Two-Step Ownership**
   - Test transferOwnership() flow
   - Test acceptOwnership() flow
   - Test pending owner view
   - Test cancelled transfer (transfer to address(0))

4. **Upgrade Authorization**
   - Only owner can upgrade
   - Operator cannot upgrade
   - Unauthorized cannot upgrade

5. **Proxy Protection**
   - Direct calls to implementation fail appropriately
   - Proxy delegation works correctly

## Security Considerations

### Additions

- **UUPS Upgrade Safety**: Can't accidentally remove upgradeability (UUPSUpgradeable enforces this)
- **Two-Step Ownership**: Prevents accidental ownership transfer to wrong/invalid address
- **Initialization Protection**: `initializer` modifier prevents re-initialization attacks

### Preserved

- Reentrancy protection on `manage()` and withdrawal functions
- Authorization checks on `manage()` calls
- Role separation between owner and operator
- SafeERC20 usage for token transfers

### New Attack Vectors

- **Storage Collision**: Must carefully manage storage layout in upgrades (no storage gaps means manual tracking required)
- **Initialization Front-Running**: Deploy and initialize in same transaction to prevent front-running

## Backwards Compatibility

### Breaking Changes

1. **Deployment Pattern**: Requires proxy deployment instead of direct deployment
2. **Ownership Transfer**: Now requires two steps (transfer → accept)
3. **Events**: Adds `OwnershipTransferStarted` event

### Preserved Functionality

- All operator functions unchanged
- Authorization system unchanged
- Withdrawal functions unchanged
- `manage()` function unchanged
- All function signatures preserved

## Implementation Checklist

- [ ] Update contract imports
- [ ] Change inheritance to upgradeable versions
- [ ] Replace constructor with initialize()
- [ ] Add _authorizeUpgrade() function
- [ ] Update deployment script for proxy pattern
- [ ] Update tests to use proxy deployment
- [ ] Add upgrade tests
- [ ] Add two-step ownership tests
- [ ] Update SDK for proxy awareness
- [ ] Update dev-scripts for proxy deployment
- [ ] Update CLAUDE.md documentation

## Open Questions

None - design approved for implementation.

## References

- [OpenZeppelin UUPS](https://docs.openzeppelin.com/contracts/5.x/api/proxy#UUPSUpgradeable)
- [OpenZeppelin Ownable2Step](https://docs.openzeppelin.com/contracts/5.x/api/access#Ownable2Step)
- [EIP-1822: UUPS](https://eips.ethereum.org/EIPS/eip-1822)
- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
