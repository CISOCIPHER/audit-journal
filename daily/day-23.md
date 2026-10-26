# Day 23 — The Rewarder

## What I tackled
Damn Vulnerable DeFi: The Rewarder. A Merkle-proof + bitmap reward distributor
that lets a claimer batch multiple claims in one transaction.

## What I did
Read `claimRewards` in `TheRewarderDistributor.sol` line by line. The "already
claimed" bitmap is only stamped via `_setClaimed` when the token changes
between claims, or on the very last claim in the array — not after each
individual claim. The token transfer, however, fires on every single claim in
the loop with no such guard.

That means if you put your own (valid, Merkle-proof-backed) claim in the
array N times for the same token, every copy gets paid before the stamp ever
lands. I built a `Claim[]` array repeating my DVT claim ~1999 times and my
WETH claim ~1999 times, called `claimRewards` once, and swept the proceeds to
`recovery`.

## Finding: Claim-replay via deferred bitmap stamping
**Tool:** Foundry (forge test, manual trace reading)
**Severity:** Critical
**Triage:** The `AlreadyClaimed` bitmap check in `claimRewards` is only
enforced once per token-group in a batch (on token switch or array end),
while the token transfer executes unconditionally on every loop iteration.
A caller with any single valid leaf can replay it arbitrarily within one
transaction and drain the distributor before the "claimed" state is ever
checked. Fix: move the bitmap check (and revert) to run before every
transfer, not once per batch.

## What I learned
"Batching" claims for efficiency is a classic place to introduce a
check-after-action bug: the code optimizes WHEN it writes state (once per
batch) but forgets that state must be checked before EVERY payout, not after
the fact. Pay-first-check-later is dangerous even when the check does
eventually run.

## Links used
- src/the-rewarder/TheRewarderDistributor.sol
- test/the-rewarder/TheRewarder.t.sol
