# Day 17 — Invariant Testing with Foundry

## What I tackled
Moved from fuzz testing (Day 16, one function, random single inputs) to invariant
testing — checking a rule that must hold true across random SEQUENCES of multiple
function calls, not just one call at a time.

## What I did
1. Wrote a first invariant test on VulnerableBank.sol: `assertGe(address(bank).balance, 0)`.
   It passed — but this was a weak invariant, since a balance can never be negative
   anyway. It couldn't have caught any real bug.
2. Rewrote it as a meaningful check: does the bank's real ETH balance actually match
   what its internal notebook (`balances` mapping) says people are owed?
3. Built an `Attacker.sol` contract that deposits ETH, then reenters `withdraw()` from
   its `receive()` function — the same reentrancy pattern Mythril flagged on Day 16 —
   and wrote a test that runs this attack and checks the invariant before and after.

## Finding: Reentrancy pattern confirmed, but blocked by Solidity 0.8 checked arithmetic
**Tool:** Foundry (manual exploit test, invariant-style assertion)
**Severity:** Informational / Low (for this exact contract) — the underlying pattern is
still a real finding and would be Medium/High in a different context
**Triage:** The reentrant call chain genuinely nested three levels deep (confirmed in
the trace: `receive -> withdraw -> receive -> withdraw...`), proving the vulnerable
pattern is real and matches Mythril's SWC-107 finding from Day 16. However, when the
nested calls tried to subtract more than the attacker's recorded balance, Solidity 0.8's
built-in underflow protection reverted the subtraction — and because the contract uses
`require(success, "Transfer failed")` after the low-level call, that revert cascaded
back up and cancelled the entire transaction, undoing the attack. So the vulnerable
*pattern* is present and worth flagging, but actual fund drainage was not achievable
with this specific exploit, in this specific contract, under Solidity 0.8.13's checked
math.

## What I learned
- A weak invariant (like "balance >= 0") can pass without testing anything meaningful —
  always check what a rule would need to be false before trusting that it passed.
- Static/symbolic tools like Mythril are right to flag the CEI (checks-effects-interactions)
  violation as a pattern — but whether it's actually exploitable for profit depends on
  the exact surrounding code (checked math, success checks, etc). Severity should reflect
  real-world exploitability, not just pattern presence.
- Reentrancy can still happen (the call chain proves it) even when the attacker walks
  away with nothing, because the damage and the vulnerability are two separate questions.

## Links used
- https://book.getfoundry.sh/forge/invariant-testing
- https://swcregistry.io/docs/SWC-107
