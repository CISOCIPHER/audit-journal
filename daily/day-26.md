# Day 26 — Puppet V2

## What I tackled
Damn Vulnerable DeFi: Puppet V2. Same oracle-manipulation family as Day 25's
Puppet, but upgraded to Uniswap V2: the lending pool prices its WETH
collateral requirement using the official `UniswapV2Library.getReserves` +
`quote` helpers against a live pair, still with no TWAP.

## What I did
`PuppetV2Pool._getOracleQuote` reads the pair's current reserves straight
from `getReserves` and quotes off them on the spot — using the "official"
Uniswap library doesn't fix the underlying problem, it's still an
instantaneous ratio with no time-weighting or history check.

Exploit: swap my entire DVT balance (10,000 tokens, against a pool with only
100 DVT / 10 WETH) through the Uniswap V2 router for ETH, which guts the
token's WETH price in one trade. Wrap just enough of the resulting ETH into
WETH to cover the now-microscopic deposit requirement, borrow the pool's
entire 1,000,000 DVT for that tiny amount, and forward it to recovery.

## Finding: V2 oracle still reads manipulable spot reserves
**Tool:** Foundry (forge test)
**Severity:** Critical
**Triage:** Swapping from a manual spot-price formula (Puppet V1) to
Uniswap's own library functions doesn't add protection — `getReserves` and
`quote` are still reading the pair's current balances, which any sufficiently
large trade can move within a single transaction. The underlying library
being "official" has nothing to do with whether the price source itself is
safe. Fix: TWAP (Uniswap V2 has a built-in cumulative price mechanism made
for exactly this) or an external oracle, never raw reserves.

## What I learned
It's tempting to assume a bug is fixed because the code now calls a
well-known, audited library — but a correctly-implemented spot-price read is
still a spot price. The library isn't the vulnerability; the *design
decision* to trust an instantaneous AMM ratio as a price oracle is, and
that decision gets carried over unchanged from V1 to V2 here.

## Links used
- src/puppet-v2/PuppetV2Pool.sol
- test/puppet-v2/PuppetV2.t.sol
