# Day 30 — ABI Smuggling (bonus, post-deadline wrap)

## What I tackled
With the 30-day mark reached, I closed out one more Damn Vulnerable DeFi challenge instead of stopping cold: "ABI Smuggling", a permission-checking bug in a self-authorized vault that reads a function selector from a hardcoded calldata offset instead of trusting its own ABI decoding.

## What I did
`AuthorizedExecutor.execute(address target, bytes calldata actionData)` is meant to only allow a caller to run `actionData` on `target` if they hold permission for that exact selector. To get the selector cheaply, it skips proper ABI decoding and just does `calldataload` at a fixed byte offset — `4 + 32*3 = 100` — on the theory that that's always where a normally-encoded `bytes` argument's content begins.

That assumption only holds if the calldata was encoded "the normal way." Since `actionData` is ABI-encoded as a dynamic `bytes` parameter, its real position is wherever the offset word (at calldata position 36) points, not necessarily position 100. So I hand-built the raw calldata instead of letting Solidity auto-encode it:
- Target param = the vault (as normal).
- Offset word set to `0xA0` (160) instead of the standard `0x40` — pointing the *real* dynamic data far past where the permission check looks.
- Bytes `[100:132)` (what the check actually reads) filled with `withdraw`'s selector — a selector the player legitimately holds permission for.
- The real length + content, starting at the offset I specified, holding `sweepFunds(recovery, token)` — the privileged call only the deployer is allowed to make.

`target.functionCall(actionData)` then correctly ABI-decodes `actionData` per the real offset/length fields and executes `sweepFunds`, while the permission check upstream saw `withdraw` and let it through.

`forge test --match-path test/abi-smuggling/ABISmuggling.t.sol -vv` → `[PASS] test_abiSmuggling() (gas: 54767)`.

## Finding: Fixed-offset selector read for permission checks can diverge from the actual ABI-decoded call that executes
**Tool:** Manual review (Foundry PoC)
**Severity:** Critical
**Triage:** Never infer a dynamic parameter's structure from a fixed calldata offset — always decode it properly (e.g. `abi.decode` or a library that respects the real offset/length words) before inspecting any part of it for an authorization decision. The cost of correct decoding is trivial next to the cost of a permission check that can be made to look at different bytes than the ones that actually execute.

## What I learned
This is the sharpest version yet of a theme that ran through the whole 30 days: a check is only as good as its guarantee that it inspected the *same* data that gets acted on. Day 27's payment-order bug, Day 29's post-hoc readiness check, and this one are all variations of the same root failure — validating something other than the exact bytes that end up mattering. Calldata in particular is attacker-controlled raw bytes; any shortcut that assumes a "normal" encoding instead of actually decoding it is an opening.

## Links used
- Damn Vulnerable DeFi v4 — ABI Smuggling challenge
- Solidity ABI encoding spec for dynamic types (offset/length/content layout)

---

## Closing note — 30-day challenge retrospective
Finished the self-paced 30-day Damn Vulnerable DeFi v4 security audit challenge: 29 challenges solved across the scheduled window, plus this bonus 30th on wrap day. Vulnerability classes covered end to end: reentrancy and accounting bugs (The Rewarder), oracle manipulation both naive and "official" (Compromised, Puppet, Puppet V2), flash-swap/flash-loan combos (Free Rider), payment-order inversions and unchecked batch state (Free Rider, Backdoor), unvalidated delegatecall during initialization (Backdoor), post-hoc authorization checks in a timelock (Climber), and fixed-offset calldata parsing diverging from real ABI decoding (ABI Smuggling). Not reached in the window: Wallet Mining, Puppet V3, Shards, Curvy Puppet, Withdrawal — noted here rather than skipped silently, as candidates to revisit.

The throughline across all of it: nearly every bug was code that looked correct read top to bottom, and broke only once you tracked exactly which state a check relied on versus which state the following code actually acted on. That gap — between what was verified and what was executed — is the pattern to keep hunting for going forward.
