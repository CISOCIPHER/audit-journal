# Day 3 — EVM Basics: call vs delegatecall

**Date:** 2026-09-24

## What I tackled
Understanding the difference between CALL, DELEGATECALL, and STATICCALL, and why proxy contracts specifically rely on delegatecall.

## What I did
Went through the CALL, DELEGATECALL, CALLCODE, and STATICCALL entries on evm.codes.
Sketched a 3-box diagram: User -> Proxy -> (delegatecall) -> Logic contract.

## What I learned
CALL and STATICCALL run code in the callee's own storage/context. DELEGATECALL
runs the callee's code but inside the CALLER's storage and identity - it
"persists the current values for sender and value." This is exactly how proxy
contracts work: the Proxy holds all real data and never changes address, while
it delegatecalls into a separate Logic contract that holds only code. This
lets teams upgrade a contract's logic without losing data or changing the
address users interact with. It's also why storage layout (Day 2) matters so
much - if Proxy and Logic disagree on variable order, storage gets corrupted.

## Links used
- [evm.codes](https://www.evm.codes/)
