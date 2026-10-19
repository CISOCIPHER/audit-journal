# Day 22 — Damn Vulnerable DeFi: Selfie

## What I tackled
The Selfie challenge from Damn Vulnerable DeFi. A lending pool offers flash loans of a token that is also the governance voting token. A governance contract lets anyone with more than half of the supply queue an action, which can be executed after a waiting period. The pool has an `emergencyExit(receiver)` function that only governance can call. The goal was to drain the pool into a recovery account.

## What I did
- Read `queueAction` and `_hasEnoughVotes` in `SimpleGovernance.sol` and listed the functions in `SelfiePool.sol`.
- Wrote `SelfieAttacker.sol`: it flash-borrows the pool's tokens, delegates the votes to itself, queues `emergencyExit(recovery)` as a governance action, then approves the pool to take the tokens back.
- In the test, advanced time by 2 days with `vm.warp` and called `executeAction` on the queued action.
- Ran `forge test --match-contract SelfieChallenge -vvvv`. It passed (2 passed, 0 failed): pool balance 0, recovery received 1.5e24 tokens.

## Finding: Governance voting power can be flash-borrowed
**Tool:** Foundry (forge test -vvvv), manual code review
**Severity:** Critical
**Triage:** Confirmed. `_hasEnoughVotes()` compares `getVotes(who)` (current voting power) against half of `totalSupply()` at the moment of queuing. The same token is lendable through `flashLoan()`, so a borrower can hold a majority for one transaction, delegate it to themselves, queue any action, and repay. The queued action later executes with governance authority, and `emergencyExit` sends the pool's entire balance to an address the attacker chooses.

Fix: measure voting power at a past block or snapshot (for example `getPastVotes`), not live balances. Also consider a minimum holding period, excluding loaned tokens from voting, a guardian who can cancel queued actions, and not making the lendable token the governance token.

## What I learned
- Anything that is measured "right now" can be borrowed for one transaction.
- Governance attacks and flash loan attacks are the same family: temporary balance, permanent consequences.
- The waiting period did not help. The action is queued once and runs later, after the loan is gone.
- Voting power in ERC20Votes only counts after `delegate()`, so tokens must be delegated before voting.

## Links used
- https://www.damnvulnerabledefi.xyz/
- https://book.getfoundry.sh/
- https://docs.openzeppelin.com/contracts/5.x/governance
