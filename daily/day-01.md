# Day 1 — Environment Setup

**Date:** 2026-09-21

## What I tackled
Setting up and verifying my Foundry toolchain before touching any real audit work.

## What I did
```bash
forge --version
cast --version
anvil --version
forge init my-audit-practice
cd my-audit-practice
forge build
forge test -vvv
```

## Evidence
![Foundry version check](../evidence/day-01/versions.png)
![forge test passing](../evidence/day-01/tests-passing.png)

## What I learned
A clean, verified dev environment is step zero for any real audit — you can't
trust findings from a toolchain you haven't confirmed works. Also learned the
difference between Forge (build/test), Cast (CLI for chain interaction), and
Anvil (local node).

## Links used
- [Foundry Book — Getting Started](https://book.getfoundry.sh/)
