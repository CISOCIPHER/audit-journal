# Day 24 — Compromised

## What I tackled
Damn Vulnerable DeFi: Compromised. A "trustful" price oracle that takes the
median of 3 reporter-submitted prices for an NFT, and an exchange that buys
and sells that NFT at whatever the oracle says.

## What I did
The challenge drops a fake leaked HTTP response in its README containing two
blocks of hex-encoded bytes. Decoded (hex -> ASCII -> base64 -> private key),
they turned out to be the private keys for 2 of the exchange's 3 "trusted"
oracle sources. With 2 of 3 reporters compromised, I fully control the
median price of any 3-value set, since I can force two entries to agree on
any number I want.

Exploit: post price 0 from both compromised sources, buy the NFT for
basically nothing, post price = the exchange's entire ETH balance from both
compromised sources, sell the NFT back for that full balance, sweep it to
recovery, then quietly restore the price to its original value so the
oracle looks untouched.

## Finding: Price oracle trust threshold compromised via leaked signer keys
**Tool:** Foundry (forge test), manual hex/base64 decoding
**Severity:** Critical
**Triage:** A median-of-3 oracle is only as safe as its worst 2 signers.
Leaking any 2 of 3 private keys gives full price control, which cascades
into a complete buy-low/sell-high drain of any contract pricing off that
oracle. Fix: raise the quorum/threshold relative to signer count, monitor
for off-pattern price posts, and treat any key material appearing in logs,
error pages, or HTTP responses as compromised immediately.

## What I learned
A "trustful" oracle's security model collapses the moment trust is split
unevenly — 2-of-3 sounds safe until you realize an attacker only needs a
simple majority, not all of them. Key leakage via a web service response is
a very real, very mundane way for that to happen; the bug here wasn't in
Solidity at all, it was in operational security off-chain.

## Links used
- src/compromised/TrustfulOracle.sol
- src/compromised/Exchange.sol
- test/compromised/Compromised.t.sol
