# Day 15 — Static Analysis with Slither

## What I tackled
Learned to use Slither, a static analysis tool, to automatically scan Solidity
contracts for known bug patterns — and practiced triaging its output (deciding
what's a real risk vs. noise).

## What I did
- Installed/confirmed Slither (v0.11.6)
- Ran `slither .` on my own practice contracts (my-audit-practice) — 8 results,
  all gas-optimization suggestions (constable-states, immutable-states), no
  real security issues
- Cloned OpenZeppelin's contracts repo and ran Slither against two real,
  widely-used contracts: ERC20.sol and ERC721.sol
- Both scans returned only 1 finding each — "different Solidity versions used"
  across imported files — informational only, not a real vulnerability

## Finding: Different Solidity versions used (ERC20.sol & ERC721.sol)
**Tool:** Slither (solc-version detector)
**Severity:** Informational
**Triage:** Not a real issue. Interface files intentionally support older
compiler versions since they contain no logic, only function signatures. The
actual implementation files use a modern, locked version. OpenZeppelin
controls the exact compiler version used at deployment, so no real risk.

## What I learned
- Slither is a tool that reads source code and flags known bug patterns —
  fast, consistent, but doesn't understand business logic the way a human does
- Triage is deciding which findings are real risks vs. noise, like a nurse
  sorting patients in an ER
- Clean results on mature, widely-used code (like OpenZeppelin's) is expected
  and reassuring — it confirms the tool and process work correctly
- Real auditors document every finding, even ones dismissed as non-issues,
  so nothing looks "missed"

## Links used
- https://github.com/crytic/slither
- https://github.com/OpenZeppelin/openzeppelin-contracts
