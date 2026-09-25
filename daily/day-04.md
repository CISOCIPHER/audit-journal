# Day 4 — Access Control & Visibility

**Date:** 2026-09-26

## What I tackled
Access control and visibility bugs - a function meant to be restricted ends
up callable by anyone.

## What I did
Exploited Ethernaut Level 1 (Fallback) live on Sepolia:
1. Called contribute() with 0.0001 ETH to get contributions[me] > 0
2. Called sendTransaction() to trigger receive(), which had no real
   ownership check - became owner
3. Called owner() to confirm - returned my own wallet address
4. Called withdraw() to drain the contract's balance to myself

## What I learned
Found the bug by comparing every place `owner` gets written: contribute()
requires out-contributing the existing owner (a real, if impractical,
barrier), but receive() only requires contributing >0 (no barrier at all).
Same variable, two doors, one barely locked.

The method: list every place a critical variable (owner, balance) gets
written, then compare the guard condition at each write. Inconsistent
guards on the same variable is a real, recurring bug pattern.

## Links used
- SWC-100, SWC-105
- Ethernaut Level 1 (Fallback)
