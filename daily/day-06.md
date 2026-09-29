# Day 6 — Integer Overflow/Underflow

**Date:** 2026-09-28

## What I tackled
Integer overflow/underflow - unsigned math that wraps instead of failing, and a `require` that can never catch it.

## What I did
Exploited Ethernaut Level 5 (Token) on Sepolia:
1. Confirmed starting balance: 20 tokens via balanceOf(player)
2. Called transfer() sending 21 tokens to another address - more than my balance
3. The check `require(balances[msg.sender] - _value >= 0)` passed anyway
4. Balance underflowed to 2^256 - 1 (115792089237316195423570985008687907853269984665640564039457584007913129639935)
5. Submitted instance - level completed

Also reviewed OpenZeppelin's ERC20 `_update` function on GitHub to compare a safe `unchecked{}` block: the subtraction there is guarded by `if (fromBalance < value) revert` immediately above it, so the unsigned subtraction can never wrap.

## What I learned
`require(balance - value >= 0)` on a `uint` is meaningless - unsigned integers can never be negative, so the check always passes regardless of input. In Solidity <0.8 with no SafeMath, the subtraction then wraps silently instead of reverting.

The fix is to check bounds *before* subtracting: `require(balance >= value)`. Solidity 0.8+ also reverts on overflow/underflow by default, unless wrapped in `unchecked{}`.

`unchecked{}` is safe only when a check or invariant immediately above it proves the operation can't wrap - like OpenZeppelin's `fromBalance < value` revert check. It's unsafe whenever user-controlled values feed the math without that kind of guard.

## Links used
- SWC-101
- Ethernaut Level 5 (Token)
- OpenZeppelin ERC20.sol - `_update()` function
