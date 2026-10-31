# Day 27 — Free Rider

## What I tackled
Damn Vulnerable DeFi's "Free Rider" challenge: a Uniswap V2-integrated NFT marketplace with a payment-ordering bug and a batch-purchase bug that combine into a near-free sweep of all 6 NFTs, plus a recovery-manager bounty flow to collect on top.

## What I did
`FreeRiderNFTMarketplace._buyOne` transfers the NFT to the buyer *before* paying the seller, then pays `_token.ownerOf(tokenId)` — which by that point is the buyer, not the seller. `buyMany` loops `_buyOne` for an array of token IDs, but each iteration checks `msg.value < priceToPay` against the same undiminished `msg.value`, so one NFT's price satisfies the check for every NFT in the batch.

Combined: pay the price of a single NFT, call `buyMany` for all 6, and the marketplace refunds that same payment back to the buyer on every iteration — draining its full prefunded ETH balance while handing over all 6 NFTs for free.

Since the player only starts with 0.1 ETH (NFT price is 15 ETH), I flash-swapped the 15 ETH entry price as WETH straight from the Uniswap V2 pair (`pair.swap` with calldata to trigger `uniswapV2Call`), unwrapped it, ran the `buyMany` exploit to pick up all 6 NFTs plus the marketplace's 90 ETH balance, repaid the flash swap with its 0.3% fee, then forwarded the NFTs into `FreeRiderRecoveryManager` — the last transfer's `data` encoded as the player's address to trigger the 45 ETH bounty payout — and swept the remaining profit to the player.

`forge test --match-path test/free-rider/FreeRider.t.sol -vv` → `[PASS] test_freeRider() (gas: 1047108)`.

## Finding: Payment-order inversion + undiminished batch payment check allow draining marketplace ETH and acquiring all listed NFTs for the price of one
**Tool:** Manual review (Foundry PoC)
**Severity:** Critical
**Triage:** `_buyOne` must resolve and cache the seller's address *before* transferring the NFT, not after, and `buyMany` must decrement a running payment total (or require exact per-item payment) rather than re-checking the same `msg.value` on every loop iteration. As written, a single payment can buy an unlimited batch and simultaneously refund itself from the marketplace's own balance.

## What I learned
Payment-ordering bugs are easy to miss because each line looks locally correct — the real bug only appears once you track *who* `ownerOf` resolves to at the exact moment the payment line executes, after a state-changing call earlier in the same function already moved ownership. Flash swaps are also a clean way to front capital you don't have when the exploit's "investment" step is itself the profitable step — no separate attacker balance is ever really at risk.

## Links used
- Damn Vulnerable DeFi v4 — Free Rider challenge
- Uniswap V2 flash swap mechanics (`swap` + `uniswapV2Call`)
