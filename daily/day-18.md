# Day 18 — Damn Vulnerable DeFi: Truster (Arbitrary Call Injection)

## What I tackled
Solved the Truster challenge on Damn Vulnerable DeFi — a flash-loan lending pool
that lets the borrower tell it to execute an arbitrary function call, on any
contract, with any data, during the loan.

## What I did
1. Reviewed `TrusterLenderPool.sol`'s `flashLoan()` function and found the
   vulnerable line: `target.functionCall(data)` — the pool executes whatever
   instruction the borrower hands it, with no restriction on what that
   instruction does.
2. Realized the exploit doesn't need the loan itself at all — the borrower can
   just instruct the pool to call `token.approve(attacker, amount)` on itself,
   since the call executes with the pool as `msg.sender`.
3. Built `TrusterAttacker.sol`, a contract whose constructor: requests a 0-token
   flash loan while handing over an `approve()` instruction as the "callback"
   data, then immediately calls `transferFrom()` to drain the pool's full
   balance to a recovery address — all inside one constructor, satisfying the
   challenge's "single transaction" rule.
4. Ran `forge test --match-contract TrusterChallenge -vvvv` and confirmed the
   exploit: pool balance went to 0, recovery account received the full
   1,000,000 tokens, and the player's nonce stayed at 1 (one transaction).

## Finding: Unrestricted arbitrary external call in flashLoan()
**Tool:** Manual review + Foundry (exploit built and proven as a test)
**Severity:** Critical
**Triage:** Real, directly exploitable. The pool grants an external, arbitrary
call to a borrower-controlled target with borrower-controlled calldata, inside
a function where the call executes with the pool's own authority. This lets an
attacker bypass the flash loan entirely and directly command the pool to
approve away its own token balance. Root cause: no restriction on which
functions/contracts the "callback" can target, and no check on what the call
is allowed to do on the pool's behalf.

## What I learned
- Not every DeFi bug is reentrancy or bad math — this one was about *trust*:
  the pool trusted the borrower's instruction without limiting what it could
  do using the pool's own authority.
- A contract's constructor counts as a single transaction no matter how much
  logic runs inside it — useful for solving challenges that require the whole
  exploit to happen in one transaction from an EOA.
- Low-level arbitrary calls (`functionCall`, raw `.call()`) driven by
  caller-supplied data are a recurring red flag worth specifically checking
  for in any contract that accepts bytes as a parameter.

## Links used
- https://www.damnvulnerabledefi.xyz/challenges/truster/
- https://docs.openzeppelin.com/contracts/4.x/api/utils#Address-functionCall-address-bytes-
