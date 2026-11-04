# Day 29 — Climber

## What I tackled
Damn Vulnerable DeFi's "Climber" challenge: a timelock-governed, UUPS-upgradeable vault, where the timelock's own execution function verifies state in the wrong order.

## What I did
`ClimberTimelock.execute()` is public — anyone can call it with arbitrary `targets`/`values`/`dataElements`/`salt`. It runs every call in the batch first, and only *after* the loop checks `getOperationState(id) == ReadyForExecution`, reverting if not. Nothing stops the batch itself from making that check pass by the time it's reached — the calldata can retroactively schedule its own operation with a zero delay before the check ever runs.

So a single `execute()` call carried four steps, each running with `msg.sender == address(timelock)` since they're dispatched via `targets[i].functionCallWithValue(...)` from inside the timelock contract itself:
1. `grantRole(PROPOSER_ROLE, attacker)` — succeeds because the timelock has `ADMIN_ROLE` on itself (self-administration), and `ADMIN_ROLE` is `PROPOSER_ROLE`'s role-admin.
2. `updateDelay(0)` — collapses the normal 1-hour delay to zero.
3. `vault.upgradeToAndCall(maliciousImpl, drainCalldata)` — passes `onlyOwner` because `vault.owner() == address(timelock)`, and runs the malicious implementation's `drain()` function via delegatecall in the same transaction, sweeping the vault's full DVT balance to `recovery`. (The malicious implementation had to inherit `UUPSUpgradeable` itself — `upgradeToAndCall` validates the new implementation via `proxiableUUID()`, so a bare contract gets rejected with `ERC1967InvalidImplementation`.)
4. `attacker.scheduleSelf()` — now holding `PROPOSER_ROLE`, calls `timelock.schedule()` with the *exact same* targets/values/dataElements/salt as the operation currently executing, satisfying the check that fires right after this loop ends.

`forge test --match-path test/climber/Climber.t.sol -vv` → `[PASS] test_climber() (gas: 2043212)`.

## Finding: execute() validates operation readiness after running arbitrary calldata, letting a batch retroactively authorize and schedule itself
**Tool:** Manual review (Foundry PoC)
**Severity:** Critical
**Triage:** The `ReadyForExecution` check must happen *before* any calls in the batch run, not after. As written, `execute()`'s own side effects can satisfy its own precondition — turning a timelock meant to enforce a mandatory delay into something an attacker can bypass entirely in one atomic transaction, including self-granting the role needed to do it.

## What I learned
This is the same family of bug as Free Rider's payment-order inversion — a check placed after a state-changing action instead of before — but at a much higher blast radius, because the "state" being checked is the authorization for the very code that's running. Any time a function validates "is this allowed" using state that earlier code in the *same call* could have mutated, that validation is advisory at best. Also a good reminder that `onlyOwner`/role checks are about `msg.sender`, not about *who initiated the outer transaction* — a contract executing calls on your behalf inherits its own identity for every downstream call it makes.

## Links used
- Damn Vulnerable DeFi v4 — Climber challenge
- OpenZeppelin UUPSUpgradeable / ERC1967Proxy upgrade mechanics
