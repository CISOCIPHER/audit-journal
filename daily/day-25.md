# Day 25 — Puppet

## What I tackled
Damn Vulnerable DeFi: Puppet. A lending pool that prices its collateral
requirement off a Uniswap V1 pair's live spot balance, with no time-weighted
average or sanity bound.

## What I did
`PuppetPool._computeOraclePrice()` is just
`uniswapPair.balance * 1e18 / token.balanceOf(uniswapPair)` — the raw,
instantaneous reserve ratio of a thinly-liquid pool (only 10 ETH / 10 DVT at
setup). That number moves however far a single trade pushes it, and nothing
checks it against history.

The win condition also required the whole exploit to run as exactly one
transaction from the player (`vm.getNonce(player) == 1`). Since nonce only
increments on contract *creation*, not on ordinary calls, the fix was to
deploy one attacker contract and let a post-construction function do the
rest of the work, rather than cramming everything into the constructor.

Exploit: dump the player's entire DVT balance into the Uniswap pair
(`tokenToEthSwapInput`), which craters the token's ETH price since the pool
is so thin. `calculateDepositRequired` on the lending pool now returns next
to nothing, so I borrow the pool's entire DVT balance for pocket change and
forward it to recovery.

## Finding: Lending pool prices collateral off a manipulable AMM spot price
**Tool:** Foundry (forge test)
**Severity:** Critical
**Triage:** Using a live DEX reserve ratio as a price oracle lets any single
large trade, within one transaction, move the "price" however the attacker
wants — especially against a shallow pool. The borrow requirement computed
from that price inherits the manipulation instantly. Fix: use a
time-weighted average price (TWAP) or an external oracle (e.g. Chainlink)
instead of spot reserves, and/or require multi-block price observation.

## What I learned
"On-chain price" and "safe price" are not the same thing. A spot ratio from
an AMM is trivially manipulable within a single block/transaction if the
pool is small relative to the attacker's capital — no flash loan was even
needed here, the player's own starting balance was enough. Also: Foundry's
nonce only tracks contract *deployments*, not calls, which is worth
remembering for any "single transaction" constraint.

## Links used
- src/puppet/PuppetPool.sol
- src/puppet/IUniswapV1Exchange.sol
- src/puppet/PuppetAttacker.sol
- test/puppet/Puppet.t.sol
