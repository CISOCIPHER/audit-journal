# Day 21 — Damn Vulnerable DeFi: Unstoppable

## What I tackled
The Unstoppable challenge from Damn Vulnerable DeFi. A tokenized vault offers flash loans, and a monitor contract checks that those loans still work. If a check fails, the monitor pauses the vault and hands ownership back to the deployer. The goal was to make the flash loan feature stop working.

## What I did
- Read `flashLoan()` in `UnstoppableVault.sol` and found the invariant check at the start of the function.
- Wrote a one-line exploit in `test_unstoppable()`: `token.transfer(address(vault), 1)`.
- Ran `forge test --match-contract UnstoppableChallenge -vvvv`. It passed (2 passed, 0 failed).
- Read the trace: `flashLoan` reverted with `InvalidBalance()`, then the monitor called `setPause(true)` and `transferOwnership(deployer)`.

## Finding: Flash loans permanently blocked by a strict balance equality check
**Tool:** Foundry (forge test -vvvv), manual code review
**Severity:** Medium (denial of service; no funds stolen, but a core feature is disabled for everyone)
**Triage:** Confirmed. `flashLoan()` requires `convertToShares(totalSupply) == totalAssets()` before every loan. `totalAssets()` reads the vault's real token balance, but `totalSupply` only changes through `deposit()` and `mint()`. Anyone can send tokens straight to the vault's address, which raises the balance without issuing shares, so the equality fails on every later call.

Fix: do not use strict equality against a balance that outsiders can change. Track assets with an internal accounting variable, or allow a tolerance, or remove the check.

## What I learned
- A contract can't assume its own functions are the only way value gets in. Tokens (and ETH) can always be sent straight to an address.
- Strict `==` checks on balances are a classic denial-of-service switch.
- This is the same family as Day 19 (Side Entrance): the code trusted a balance and forgot another door exists.
- A tiny action (1 token unit) can disable a whole feature without stealing anything, so severity is about availability, not theft.

## Links used
- https://www.damnvulnerabledefi.xyz/
- https://book.getfoundry.sh/
- https://eips.ethereum.org/EIPS/eip-4626
