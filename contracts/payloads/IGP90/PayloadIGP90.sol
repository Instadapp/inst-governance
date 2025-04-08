pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

import {IGovernorBravo} from "../common/interfaces/IGovernorBravo.sol";
import {ITimelock} from "../common/interfaces/ITimelock.sol";

import {IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs} from "../common/interfaces/IFluidLiquidity.sol";
import {IFluidReserveContract} from "../common/interfaces/IFluidReserveContract.sol";

import {IFluidVaultFactory} from "../common/interfaces/IFluidVaultFactory.sol";
import {IFluidDexFactory} from "../common/interfaces/IFluidDexFactory.sol";

import {IFluidDex, IFluidAdminDex, IFluidDexResolver} from "../common/interfaces/IFluidDex.sol";

import {IFluidVault, IFluidVaultT1} from "../common/interfaces/IFluidVault.sol";

import {IFTokenAdmin, ILendingRewards} from "../common/interfaces/IFToken.sol";

import {ISmartLendingAdmin} from "../common/interfaces/ISmartLending.sol";
import {ISmartLendingFactory} from "../common/interfaces/ISmartLendingFactory.sol";

import {ICodeReader} from "../common/interfaces/ICodeReader.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";
import {PayloadIGPMain} from "../common/main.sol";

contract PayloadIGP90 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 90;

    function execute() public virtual override {
        super.execute();

        // Action 1: Add 25% governance fee on all stable DEXes
        action1();

        // Action 2: Add USDe-USDT Dex Fee Handler
        action2();

        // Action 3: Set launch limits for LBTC-cbBTC <> cbBTC vault
        action3();
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


    // @notice Action 1: Add 25% governance fee on all stable DEXes
    function action1() internal isActionSkippable(1) {
        uint256 revenueCut = 25 * 1e4; // 25%

        updateDexRevenueCut(1, revenueCut); // WSTETH_ETH
        updateDexRevenueCut(2, revenueCut); // USDC_USDT
        updateDexRevenueCut(3, revenueCut); // CBBTC_WBTC
        updateDexRevenueCut(4, revenueCut); // GHO_USDC
        updateDexRevenueCut(9, revenueCut); // WEETH_ETH
        updateDexRevenueCut(13, revenueCut); // RSETH_ETH
        updateDexRevenueCut(14, revenueCut); // WEETHS_ETH
        updateDexRevenueCut(15, revenueCut); // SUSDE_USDT
        updateDexRevenueCut(16, revenueCut); // EBTC_CBBTC
        updateDexRevenueCut(17, revenueCut); // LBTC_CBBTC
        updateDexRevenueCut(18, revenueCut); // USDE_USDT
        updateDexRevenueCut(19, revenueCut); // DEUSD_USDC
        updateDexRevenueCut(20, revenueCut); // USR_USDC
        updateDexRevenueCut(21, revenueCut); // EZETH_ETH
        updateDexRevenueCut(23, revenueCut); // USD0_USDC
        updateDexRevenueCut(24, revenueCut); // FXUSD_USDC
    }

    // @notice Action 2: Add USDe-USDT Dex Fee auth
    function action2() internal isActionSkippable(2) {
        address USDe_USDT_DEX = getDexAddress(18);

        // Fee Handler Addresses
        address FeeHandler = 0x855BaEf2EEBf4238e6e509c85a5277a3c5A38f9D;

        // Add new handler as auth
        DEX_FACTORY.setDexAuth(USDe_USDT_DEX, FeeHandler, true);
    }

    // @notice Action 3: Set launch limits for LBTC-cbBTC <> cbBTC vault
    function action3() internal isActionSkippable(3) {
        address LBTC_cbBTC_DEX = getDexAddress(17);
        address LBTC_cbBTC__cbBTC_VAULT = getVaultAddress(114);

        {
            // [TYPE 2] LBTC-cbBTC<>cbBTC vault
            VaultConfig memory VAULT_LBTC_cbBTC__cbBTC = VaultConfig({
                vault: LBTC_cbBTC__cbBTC_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at dex
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });
            setVaultLimits(VAULT_LBTC_cbBTC__cbBTC);

            VAULT_FACTORY.setVaultAuth(LBTC_cbBTC__cbBTC_VAULT, TEAM_MULTISIG, false);
        }
        
        {
            // Update LBTC-cbBTC<>cbBTC vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: LBTC_cbBTC__cbBTC_VAULT,
                expandPercent: 35 * 1e2, // 35%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimit: 50 * 1e18 // 50 shares
            });

            IFluidDex(LBTC_cbBTC_DEX).updateUserSupplyConfigs(config_);
        }

    }
    
    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 1_900 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 2_300 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 1_975 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 1_930 * 1e2;
    uint256 public constant mETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 1_975 * 1e2;

    uint256 public constant BTC_USD_PRICE = 85_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 5 * 1e2;

    uint256 public constant RLP_USD_PRICE = 1.16 * 1e2;
    uint256 public constant wstUSR_USD_PRICE = 1.07 * 1e2;

    function getRawAmount(
        address token,
        uint256 amount,
        uint256 amountInUSD,
        bool isSupply
    ) public view override returns (uint256) {
        if (amount > 0 && amountInUSD > 0) {
            revert("both usd and amount are not zero");
        }
        uint256 exchangePriceAndConfig_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                token
            )
        );

        (
            uint256 supplyExchangePrice,
            uint256 borrowExchangePrice
        ) = LiquidityCalcs.calcExchangePrices(exchangePriceAndConfig_);

        uint256 usdPrice = 0;
        uint256 decimals = 18;
        if (token == ETH_ADDRESS) {
            usdPrice = ETH_USD_PRICE;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = wstETH_USD_PRICE;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = weETH_USD_PRICE;
            decimals = 18;
        } else if (token == rsETH_ADDRESS) {
            usdPrice = rsETH_USD_PRICE;
            decimals = 18;
        } else if (token == weETHs_ADDRESS) {
            usdPrice = weETHs_USD_PRICE;
            decimals = 18;
        } else if (token == mETH_ADDRESS) {
            usdPrice = mETH_USD_PRICE;
            decimals = 18;
        } else if (token == ezETH_ADDRESS) {
            usdPrice = ezETH_USD_PRICE;
            decimals = 18;
        } else if (
            token == cbBTC_ADDRESS ||
            token == WBTC_ADDRESS ||
            token == eBTC_ADDRESS ||
            token == lBTC_ADDRESS
        ) {
            usdPrice = BTC_USD_PRICE;
            decimals = 8;
        } else if (token == tBTC_ADDRESS) {
            usdPrice = BTC_USD_PRICE;
            decimals = 18;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = STABLE_USD_PRICE;
            decimals = 6;
        } else if (token == sUSDe_ADDRESS) {
            usdPrice = sUSDe_USD_PRICE;
            decimals = 18;
        } else if (token == sUSDs_ADDRESS) {
            usdPrice = sUSDs_USD_PRICE;
            decimals = 18;
        } else if (
            token == GHO_ADDRESS ||
            token == USDe_ADDRESS ||
            token == deUSD_ADDRESS ||
            token == USR_ADDRESS ||
            token == USD0_ADDRESS ||
            token == fxUSD_ADDRESS ||
            token == BOLD_ADDRESS
        ) {
            usdPrice = STABLE_USD_PRICE;
            decimals = 18;
        } else if (token == INST_ADDRESS) {
            usdPrice = FLUID_USD_PRICE;
            decimals = 18;
        } else if (token == wstUSR_ADDRESS) {
            usdPrice = wstUSR_USD_PRICE;
            decimals = 18;
        } else if (token == RLP_ADDRESS) {
            usdPrice = RLP_USD_PRICE;
            decimals = 18;
        } else {
            revert("not-found");
        }

        uint256 exchangePrice = isSupply
            ? supplyExchangePrice
            : borrowExchangePrice;

        if (amount > 0) {
            return (amount * 1e12) / exchangePrice;
        } else {
            return
                (amountInUSD * 1e12 * (10 ** decimals)) /
                ((usdPrice * exchangePrice) / 1e2);
        }
    }
}
