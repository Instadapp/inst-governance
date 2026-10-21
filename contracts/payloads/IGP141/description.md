# Set Liquidity Layer Limits for the DexV2 and Money Market Proxies, and Send the Foundation's $350k October Grant

## Summary

This proposal sets **$50k** Liquidity Layer withdrawal and borrow limits for **ETH**, **USDC**, **USDT** and **WBTC** on the new **DexV2** proxy and **Money Market** proxy on Ethereum, ahead of the DexV2 private beta. It also collects the Liquidity Layer's uncollected **USDC**, **USDT** and **ETH** revenue into the Fluid Reserve and sends the Fluid Foundation's **$350k/month** October grant tranche (**90,000 USDC + 80,000 USDT + 60 ETH + 13 stETH**, ~$352k).

## Code Changes

### Action 1: Liquidity Layer Limits for the DexV2 and Money Market Proxies

| Protocol | Address |
| --- | --- |
| DexV2 proxy | TBD (set to the Ethereum deployment) |
| Money Market proxy | TBD (set to the Ethereum deployment) |

The Liquidity Layer only accepts configs for addresses with code, so both proxies must be deployed on Ethereum before this proposal executes.

For each proxy and each of ETH, USDC, USDT and WBTC:

| Side | Mode | Expand | Duration | Base | Max |
| --- | --- | --- | --- | --- | --- |
| Supply (withdrawal limit) | with interest | 20% | 12h | $50k | - |
| Borrow (debt ceiling) | with interest | 20% | 12h | $50k | $50k |

Token amounts are set at ETH $2,490 and WBTC $84,000.

### Action 2: Collect Revenue and Send the Foundation's October Grant

1. `collectRevenue` on the Liquidity Layer for USDC, USDT and ETH into the Fluid Reserve.
2. `withdrawFunds` from the Fluid Reserve to the Fluid Foundation (`0xde0377eF25aD02dBcFbc87D632E46bf1972A0Dc3`), memo "FOUNDATION GRANT":

| Token | Amount | ~USD |
| --- | --- | --- |
| USDC | 90,000 | $90,000 |
| USDT | 80,000 | $80,000 |
| ETH | 60 | $149,400 |
| stETH | 13 | $32,370 |
| **Total** | | **~$351,770** |

Amounts are fixed in token terms; any excess revenue stays in the Reserve.

## Description

1. **DexV2 / Money Market**: gives the DexV2 and Money Market proxies their initial Liquidity Layer limits for the private beta. The limits expand by 20% every 12 hours up to the $50k borrow ceiling.
2. **Foundation grant**: the October tranche of the $350,000/month grant approved in IGP-139.

## Conclusion

IGP-141 sets $50k Liquidity Layer withdrawal and borrow limits for ETH, USDC, USDT and WBTC on the DexV2 and Money Market proxies, and sends the Fluid Foundation's ~$350k October grant tranche from collected Liquidity Layer revenue.
