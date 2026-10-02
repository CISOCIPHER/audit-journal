# Day 8 — Predictable Randomness

**Date:** 2026-10-01 (parked, revisit later)

## What I tackled
Predictable on-chain randomness - using blockhash() as a source of "random" numbers when it's actually public data anyone can read first.

## What I did
Read SWC-120. Wrote an Attack.sol contract that:
1. Reads the same blockhash(block.number - 1) the real CoinFlip contract uses
2. Runs the identical math (blockValue / FACTOR) to predict the outcome before calling
3. Calls CoinFlip.flip(side) with the pre-computed answer instead of a real guess

Deployed Attack.sol on Sepolia, targeting a live Ethernaut Coinflip instance. Hit a wall of MetaMask RPC failures ("Failed to fetch", endpoint rate-limited) that made several attack() calls either silently cancel or revert via my own lastHash same-block guard. Switched Sepolia's RPC to a different endpoint (publicnode) mid-session, which resolved the connection errors but didn't get consecutiveWins above 0 before I ran out of time to debug further.

## What I learned
The vulnerability itself: blockhash() looks random but isn't secret - any contract can read the same block data as the target and compute the "random" result before guessing, turning a coin flip into a certainty. The real defense is an off-chain randomness source (e.g. Chainlink VRF), not block data.

Separately learned a practical lesson: MetaMask's gas estimation can throw a false "likely to fail" warning on blockhash-dependent contracts, because its simulation doesn't always match the real execution context. Force-sending past that warning is sometimes correct - but a genuine on-chain revert (checked via Remix's transaction debugger, not just the error popup) is the only way to know what actually happened. Tooling/RPC reliability is its own category of real-world audit friction, separate from the Solidity itself.

## Status
Parked - exploit logic is correct and reviewed, execution blocked by RPC/tooling issues. Revisit to get consecutiveWins to 10 and submit.

## Links used
- SWC-120
- Ethernaut Level 3 (Coinflip)
