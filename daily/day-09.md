# Day 9 — tx.origin & Signature Replay

**Date:** 2026-10-02

## What I tackled
Two authentication bugs: using tx.origin instead of msg.sender for permission checks, and accepting signatures without replay protection.

## What I did
Exploited Ethernaut Level 4 (Telephone) live on Sepolia:
1. Deployed an Attack contract with one function: attack(address _target) that calls ITelephone(_target).changeOwner(msg.sender)
2. Called attack() directly from my wallet, pointing it at the Telephone instance
3. Inside Telephone's changeOwner(), the check `if (tx.origin != msg.sender)` passed the wrong way: tx.origin was me (the original transaction signer), but msg.sender was my Attack contract (the direct caller) - not equal, so the ownership change went through
4. Verified: contract.owner() returned my wallet address
5. Submitted instance - level completed

## What I learned
tx.origin traces all the way back to the wallet that started the transaction, no matter how many contracts it passed through. msg.sender is only the immediate caller. A check like `tx.origin == owner` can be bypassed by routing the call through a middleman contract - msg.sender changes at each hop, but tx.origin stays fixed as the original signer.

Rule: never use tx.origin for authorization. Always use msg.sender - it can't be spoofed by an intermediate contract the way tx.origin can.

Signature replay (read, not yet exploited): a contract accepting a signed message as proof of authorization is vulnerable if it doesn't track used signatures or bind them to a specific contract/chain. The same valid signature can be resubmitted and accepted again.

## Links used
- SWC-115, SWC-121
- Ethernaut Level 4 (Telephone)
