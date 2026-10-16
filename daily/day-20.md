# Day 20 — Damn Vulnerable DeFi: Naive Receiver

## What I tackled
The Naive Receiver challenge from Damn Vulnerable DeFi. A lending pool holds 1,000 WETH and charges a fixed 1 WETH fee per flash loan. A receiver contract holds 10 WETH. Meta-transactions go through a trusted forwarder, and the pool also inherits Multicall. The goal was to drain both the receiver and the pool into a recovery account within the transaction limit.

## What I did
- Read `FlashLoanReceiver.sol`, `NaiveReceiverPool.sol`, `Multicall.sol`, `BasicForwarder.sol` and the challenge test.
- Mapped how the pieces trust each other: pool to forwarder (`_msgSender()`), forwarder to signer (EIP-712 signature), pool to Multicall (delegatecall).
- Built one forwarder request signed by the player, containing a `multicall` of 11 calls: ten `flashLoan(receiver, weth, 0, "")` calls and one `withdraw(1010 WETH, recovery)` call with the deployer's address appended.
- Ran `forge test --match-contract NaiveReceiverChallenge -vvvv`. It passed (2 passed, 0 failed): receiver 0, pool 0, recovery 1,010 WETH.

## Finding 1: Receiver never checks who initiated the flash loan
**Tool:** Foundry (forge test -vvvv), manual code review
**Severity:** High
**Triage:** Confirmed. The receiver only checks that the caller is the pool. The `initiator` parameter of `onFlashLoan` is unnamed and never used. The pool's `flashLoan()` accepts any receiver address from any caller, so anyone can force the receiver to pay the fixed 1 WETH fee repeatedly (ten zero-amount loans empty 10 WETH).

Fix: the receiver should require `initiator == address(this)` (or an owner), and the pool could require the caller to be the receiver.

## Finding 2: Spoofable `_msgSender()` through Multicall plus trusted forwarder
**Tool:** Foundry (forge test -vvvv), manual code review
**Severity:** Critical
**Triage:** Confirmed. `_msgSender()` trusts the last 20 bytes of `msg.data` whenever `msg.sender == trustedForwarder`. `Multicall.multicall()` runs each item with `delegatecall(address(this), data[i])`, which keeps `msg.sender` as the forwarder but makes `msg.data` equal to the attacker-controlled `data[i]`. The forwarder only verifies the outer request, so an attacker can append any address (here the deployer, who owns the pool's deposits) to an inner call and `withdraw()` as that address.

Fix: do not read the sender from calldata inside delegatecalled multicall items. Either the forwarder should be the only way to set the sender and Multicall must not pass through that path, or `multicall` should be made forwarder-aware and append the verified sender to each inner call.

## What I learned
- Each contract can look safe on its own and still fail when combined. The bug lived in how three pieces trust each other.
- A delegatecall keeps `msg.sender` but replaces `msg.data`, so anything that reads sender information from calldata is dangerous inside it.
- A callback should check who started the action, not only who is calling back.
- One signed forwarder request carrying many calls counts as one transaction.

## Links used
- https://www.damnvulnerabledefi.xyz/
- https://book.getfoundry.sh/
- https://eips.ethereum.org/EIPS/eip-2771
