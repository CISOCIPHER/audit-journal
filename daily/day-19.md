# Day 19 — Damn Vulnerable DeFi: Side Entrance

## What I tackled
The Side Entrance challenge from Damn Vulnerable DeFi. A lending pool holds 1,000 ETH, offers free flash loans and lets users deposit and withdraw. The goal was to drain the pool into a recovery account.

## What I did
- Read `SideEntranceLenderPool.sol` and the challenge test to find the success conditions (pool balance 0, recovery holds 1,000 ETH).
- Wrote `SideEntranceAttacker.sol` with three functions: `attack()`, `execute()` and `receive()`.
- Wired the attacker into `test_sideEntrance()` and ran `forge test --match-contract SideEntranceChallenge -vvvv`.
- Read the call trace to confirm each step: flashLoan, execute, deposit, withdraw, receive, transfer to recovery.

## Finding: Flash loan repayment check can be satisfied by a deposit
**Tool:** Foundry (forge test -vvvv), manual code review
**Severity:** Critical (in the context of the challenge; all pool funds drained)
**Triage:** Confirmed. The exploit passes both tests (2 passed, 0 failed).

`flashLoan()` only checks that the pool's total ETH balance is at least what it was before the loan. `deposit()` also raises the pool's balance, but it credits `balances[msg.sender]`. A borrower can deposit the borrowed ETH inside the `execute()` callback. The balance check passes, and the borrower is credited with a balance that is really the pool's own money. A later `withdraw()` takes it all.

Fix: repay the loan through a path that does not credit anyone, or block `deposit()` while a loan is active (reentrancy guard).

## What I learned
- A balance check is not an ownership check. The contract must track who owns what, not just how much it holds.
- Two functions that move money through the same door (deposit and loan repayment) can be abused against each other.
- An attacker contract needs `receive()` to accept ETH, or `withdraw()` reverts.
- This challenge has no single-transaction rule, so deploying the attacker and calling `attack()` as two steps is fine.

## Links used
- https://www.damnvulnerabledefi.xyz/
- https://book.getfoundry.sh/
