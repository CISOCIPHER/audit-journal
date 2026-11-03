# Day 28 — Backdoor

## What I tackled
Damn Vulnerable DeFi's "Backdoor" challenge: a `WalletRegistry` that auto-rewards users for creating a Gnosis Safe wallet through a factory callback, trusting the Safe's reported state without validating how it got there.

## What I did
`WalletRegistry.proxyCreated` is invoked by `SafeProxyFactory.createProxyWithCallback` right after a new Safe proxy finishes its `setup()` initializer. The registry checks the resulting Safe's threshold (must be 1), owner count (must be 1), and that the single owner is a registered beneficiary — then pays `PAYMENT_AMOUNT` DVT straight to the new wallet.

What it never checks is the `to`/`data` parameters inside the `setup()` call itself. Gnosis Safe's `setup()` accepts an optional delegatecall target, meant for installing modules during initialization — but nothing stops it pointing anywhere. I deployed a tiny helper contract (`ApprovalBackdoor`) whose only job is `token.approve(attacker, max)`, and set it as the `to` target in each Safe's own `setup()` call. Because `setup()` delegatecalls into it, the approval executes in the *new Safe's own storage context* — so by the time the Safe exists, it has already pre-approved my attacker contract for unlimited DVT, before the registry has even paid it anything.

Then it's just sequencing: create the Safe (registry pays `PAYMENT_AMOUNT` to it in the same call), immediately `transferFrom` that balance out to `recovery` using the approval that was already sitting there. Looped over all 4 users, all from inside one attacker contract's constructor, so the player's own nonce only increments once (satisfying the single-tx `_isSolved` check) despite creating 4 separate wallets and looting each one.

`forge test --match-path test/backdoor/Backdoor.t.sol -vv` → `[PASS] test_backdoor() (gas: 1537765)`.

## Finding: Unvalidated delegatecall target in Safe setup() lets an attacker pre-approve itself before the registry's reward lands
**Tool:** Manual review (Foundry PoC)
**Severity:** Critical
**Triage:** `WalletRegistry.proxyCreated` must not trust a Safe purely by its post-setup threshold/owner/beneficiary state — it has no way to know what else ran during initialization. Either reject any `setup()` call that used a non-zero `to`/`data` (no legitimate use case for a reward flow), or move the payout out of the creation flow entirely and require a separate, explicit claim step the Safe owner triggers themselves.

## What I learned
Trusting "the end state looks correct" instead of "I verified every step that produced it" is a recurring theme across this whole challenge set — Backdoor is the cleanest example yet, because the vulnerable check (threshold, owners, beneficiary) is 100% correct in isolation; the bug lives entirely in what it *doesn't* ask about. Delegatecall during a proxy's own initialization is a sharp edge worth remembering generally: anything that can execute arbitrary code in a soon-to-be-funded contract's storage context, before any of the usual access controls exist, is a preloaded backdoor by construction.

## Links used
- Damn Vulnerable DeFi v4 — Backdoor challenge
- Gnosis Safe `setup()` / `SafeProxyFactory.createProxyWithCallback` mechanics
