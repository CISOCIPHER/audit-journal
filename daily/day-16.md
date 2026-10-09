# Day 16 — Mythril & Symbolic Execution

## What I did
- Installed Mythril (v0.24.8)
- Wrote VulnerableBank.sol — a contract with a classic reentrancy bug
  (external call before state update)
- Ran `myth analyze src/VulnerableBank.sol`

## Finding: Reentrancy (SWC-107)
**Severity:** Medium
**Tool:** Mythril (symbolic execution)
Mythril simulated an attacker calling withdraw() and proved that
balances[msg.sender] -= amount executes AFTER the external .call(),
confirming a reentrancy exploit is possible — the same bug class from
Day 5, now proven mathematically rather than by inspection.
**Fix:** move the balance update before the external call, or add a
reentrancy guard.

## What I learned
Mythril doesn't just read code like Slither — it simulates real
transaction sequences to prove an exploit path exists. Slower, but
catches deeper logic bugs.

## Links used
- https://github.com/Consensys/mythril
