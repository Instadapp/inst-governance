// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {PayloadIGPPriceHelpers} from "../common/pricehelpers.sol";
import {IFluidReserveContractV2} from "../common/interfaces/IFluidReserveContract.sol";

/// @notice IGP141: Liquidity Layer limits for the DexV2 and Money Market
///         proxies, and the Foundation's October grant tranche.
///
///         Action 1 sets $50k Liquidity Layer withdrawal and borrow limits
///         for ETH, USDC, USDT and WBTC on the DexV2 proxy and the Money
///         Market proxy (mainnet private beta).
///
///         Action 2 collects the Liquidity Layer's USDC, USDT, GHO, USDe,
///         USDtb, sUSDe and ETH revenue into the Fluid Reserve and sends the
///         October tranche of the $350,000/month Foundation grant (IGP-139):
///         90,000 USDC + 80,000 USDT + 37,000 GHO + 5,000 USDe + 4,000 USDtb
///         + 1,500 sUSDe + 41 ETH + 13 stETH, ~$352k at ETH $2,490.
contract PayloadIGP141 is PayloadIGPPriceHelpers {
    uint256 public constant PROPOSAL_ID = 141;

    // --- Action 1 ---
    /// @dev DexV2 / Money Market proxies. Deployed with the Arachnid CREATE2
    ///      factory (salt 0x0003) on EmptyImplementationUUPS
    ///      0xDbd2791d64266eA070A3fEf681fb4E5b547A37C0, so the address is the
    ///      same on every chain (live on Polygon, fluid-contracts #949).
    ///      The Liquidity AdminModule requires `user.code.length > 0`
    ///      (AdminModule__AddressNotAContract, 10026), so both proxies must
    ///      be deployed on mainnet before this proposal executes.
    ///      Not the older test proxies DEX_V2_PROXY / MONEY_MARKET_PROXY in
    ///      common/constants.sol (0x4E42 / 0xe3B7), which are left untouched.
    address public constant DEXV2_LAUNCH_PROXY =
        0x17Eb78c5F7667C30ca241F56eCfE1e3b233b1E4F;
    address public constant MONEY_MARKET_LAUNCH_PROXY =
        0x2536CbF2F657F153A86aCF8435293c60A23D32bf;
    uint256 public constant DEXV2_MM_LIMIT_USD = 50_000; // $50k
    uint256 public constant DEXV2_MM_EXPAND_PERCENT = 20 * 1e2; // 20%
    uint256 public constant DEXV2_MM_EXPAND_DURATION = 12 hours;

    // --- Action 2 ---
    /// @notice October 2026 tranche of the $350,000/month Foundation grant.
    ///         Stables-first: sized to what the Reserve plus uncollected
    ///         Liquidity revenue holds at authoring (block 26243414: ~93.0k
    ///         USDC, ~83.8k USDT, ~37.1k GHO, ~5.09k USDe, ~4.09k USDtb,
    ///         ~1.52k sUSDe, ~65.3 ETH, ~53.6 stETH); ETH covers the rest.
    ///         ~$352k at ETH $2,490 and sUSDe ~$1.254; fixed token amounts, so
    ///         the USD value of the ETH / stETH legs moves with the ETH price.
    uint256 public constant FOUNDATION_GRANT_USDC = 90_000 * 1e6;
    uint256 public constant FOUNDATION_GRANT_USDT = 80_000 * 1e6;
    uint256 public constant FOUNDATION_GRANT_GHO = 37_000 * 1e18;
    uint256 public constant FOUNDATION_GRANT_USDE = 5_000 * 1e18;
    uint256 public constant FOUNDATION_GRANT_USDTB = 4_000 * 1e18;
    uint256 public constant FOUNDATION_GRANT_SUSDE = 1_500 * 1e18;
    uint256 public constant FOUNDATION_GRANT_ETH = 41 ether;
    uint256 public constant FOUNDATION_GRANT_STETH = 13 ether;

    function execute() public virtual override {
        super.execute();

        // Action 1: $50k Liquidity Layer withdrawal + borrow limits for the DexV2 and Money Market proxies.
        action1();

        // Action 2: Collect Liquidity Layer revenue and send the Foundation's October grant tranche.
        action2();
    }

    function verifyProposal() public view override {}

    function _PROPOSAL_ID() internal view override returns (uint256) {
        return PROPOSAL_ID;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Liquidity Layer limits for the DexV2 proxy and the
    ///         Money Market proxy. For ETH, USDC, USDT and WBTC each, per
    ///         proxy:
    ///         - supply: base withdrawal limit $50k, mode 1 (with interest),
    ///           expand 20% / 12h
    ///         - borrow: base and max debt ceiling $50k, mode 1, expand
    ///           20% / 12h
    ///         Same shape as the Polygon Team MS limits for these proxies.
    ///         Supply and borrow configs are both needed for every listed
    ///         token (deployment checklist, fluid-contracts #943).
    function action1() internal isActionSkippable(1) {
        address[2] memory protocols_ = [
            DEXV2_LAUNCH_PROXY,
            MONEY_MARKET_LAUNCH_PROXY
        ];

        for (uint256 p = 0; p < protocols_.length; p++) {
            _setLaunchLimitsUSD(protocols_[p], ETH_ADDRESS);
            _setLaunchLimitsUSD(protocols_[p], USDC_ADDRESS);
            _setLaunchLimitsUSD(protocols_[p], USDT_ADDRESS);
            _setLaunchLimitsUSD(protocols_[p], WBTC_ADDRESS);
        }
    }

    /// @notice Action 2: Collect the Liquidity Layer's stablecoin and ETH
    ///         revenue into the Fluid Reserve and transfer the October
    ///         tranche of the Foundation's $350,000/month grant.
    /// @dev IGP-140 Action 8 pattern (`collectRevenue`, then
    ///      `FLUID_RESERVE.withdrawFunds` to `FLUID_FOUNDATION`, memo
    ///      "FOUNDATION GRANT"), plus a stETH leg from the Reserve's Lite
    ///      revenue as in IGP-139. Fixed amounts, so any excess stays in the
    ///      Reserve.
    function action2() internal isActionSkippable(2) {
        // Step 1: Collect Liquidity Layer revenue into the Reserve.
        address[] memory liquidityTokens_ = new address[](7);
        liquidityTokens_[0] = USDC_ADDRESS; // ~71.9k uncollected
        liquidityTokens_[1] = USDT_ADDRESS; // ~61.1k uncollected
        liquidityTokens_[2] = GHO_ADDRESS; // ~37.1k uncollected
        liquidityTokens_[3] = USDe_ADDRESS; // ~5.09k uncollected
        liquidityTokens_[4] = USDTb_ADDRESS; // ~4.09k uncollected
        liquidityTokens_[5] = sUSDe_ADDRESS; // ~1.52k uncollected
        liquidityTokens_[6] = ETH_ADDRESS; // ~13.1 ETH uncollected

        LIQUIDITY.collectRevenue(liquidityTokens_);

        // Step 2: Transfer the tranche to the Fluid Foundation.
        address[] memory tokens_ = new address[](8);
        uint256[] memory amounts_ = new uint256[](8);

        tokens_[0] = USDC_ADDRESS;
        amounts_[0] = FOUNDATION_GRANT_USDC; // 90,000 USDC

        tokens_[1] = USDT_ADDRESS;
        amounts_[1] = FOUNDATION_GRANT_USDT; // 80,000 USDT

        tokens_[2] = GHO_ADDRESS;
        amounts_[2] = FOUNDATION_GRANT_GHO; // 37,000 GHO

        tokens_[3] = USDe_ADDRESS;
        amounts_[3] = FOUNDATION_GRANT_USDE; // 5,000 USDe

        tokens_[4] = USDTb_ADDRESS;
        amounts_[4] = FOUNDATION_GRANT_USDTB; // 4,000 USDtb

        tokens_[5] = sUSDe_ADDRESS;
        amounts_[5] = FOUNDATION_GRANT_SUSDE; // 1,500 sUSDe (~$1.9k)

        tokens_[6] = ETH_ADDRESS;
        amounts_[6] = FOUNDATION_GRANT_ETH; // 41 ETH

        tokens_[7] = stETH_ADDRESS;
        amounts_[7] = FOUNDATION_GRANT_STETH; // 13 stETH

        IFluidReserveContractV2(address(FLUID_RESERVE)).withdrawFunds(
            tokens_,
            amounts_,
            FLUID_FOUNDATION,
            "FOUNDATION GRANT"
        );
    }

    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    /// @dev Supply ($50k base withdrawal) + borrow ($50k base = max debt
    ///      ceiling) config at the Liquidity Layer, mode 1, 20% / 12h.
    function _setLaunchLimitsUSD(address protocol_, address token_) internal {
        setSupplyProtocolLimits(
            SupplyProtocolConfig({
                protocol: protocol_,
                supplyToken: token_,
                expandPercent: DEXV2_MM_EXPAND_PERCENT,
                expandDuration: DEXV2_MM_EXPAND_DURATION,
                baseWithdrawalLimitInUSD: DEXV2_MM_LIMIT_USD
            })
        );
        setBorrowProtocolLimits(
            BorrowProtocolConfig({
                protocol: protocol_,
                borrowToken: token_,
                expandPercent: DEXV2_MM_EXPAND_PERCENT,
                expandDuration: DEXV2_MM_EXPAND_DURATION,
                baseBorrowLimitInUSD: DEXV2_MM_LIMIT_USD,
                maxBorrowLimitInUSD: DEXV2_MM_LIMIT_USD
            })
        );
    }

    // --- BEGIN AUTO-GENERATED PRICES (scripts/verify/prepare-prices.ts) ---
    // fetched: 2026-10-21T20:06:51.248Z, source: coingecko
    function ETH_USD_PRICE()    public pure override returns (uint256) { return 2_490 * 1e2; }
    function STABLE_USD_PRICE() public pure override returns (uint256) { return 1 * 1e2; }
    function BTC_USD_PRICE()    public pure override returns (uint256) { return 84_000 * 1e2; }
    // --- END AUTO-GENERATED PRICES ---
}
