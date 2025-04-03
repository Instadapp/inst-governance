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
        action5();

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


    // @notice Action 1: Update fee of USDC-ETH DEX
    function action1() internal isActionSkippable(1) {
        {
            // wstETH-ETH DEX (Smart Collateral & Smart Debt)
            address wstETH_ETH_DEX_ADDRESS = getDexAddress(1);
            uint256 fee_ = getTradingFees(1); // Fetch Current fee: dynamic
            IFluidDex(wstETH_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }
        
        {
            // USDC-USDT DEX (Smart Debt only)
            address USDC_USDT_DEX_ADDRESS = getDexAddress(2);
            uint256 fee_ = getTradingFees(2); // Fetch Current fee: dynamic
            IFluidDex(USDC_USDT_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // cbBTC-WBTC DEX (Smart Collateral & Smart Debt)
            address cbBTC_WBTC_DEX_ADDRESS = getDexAddress(3);
            uint256 fee_ = getTradingFees(3); // Fetch Current fee: 0.01%
            IFluidDex(cbBTC_WBTC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // GHO-USDC DEX (Smart Collateral & Smart Debt)
            address GHO_USDC_DEX_ADDRESS = getDexAddress(4);
            uint256 fee_ = getTradingFees(4); // Fetch Current fee: 0.05%
            IFluidDex(GHO_USDC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // weETH-ETH DEX (Smart Collateral Only)
            address weETH_ETH_DEX_ADDRESS = getDexAddress(9);
            uint256 fee_ = getTradingFees(9); // Fetch Current fee: 0.01%
            IFluidDex(weETH_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // rsETH-ETH DEX (Smart Collateral Only)
            address rsETH_ETH_DEX_ADDRESS = getDexAddress(13);
            uint256 fee_ = getTradingFees(13); // Fetch Current fee: 0.01%
            IFluidDex(rsETH_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // weETHs-ETH DEX (Smart Collateral Only)
            address weETHs_ETH_DEX_ADDRESS = getDexAddress(14);
            uint256 fee_ = getTradingFees(14); // Fetch Current fee: 0.05%
            IFluidDex(weETHs_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // sUSDe-USDT DEX (Smart Collateral Only)
            address sUSDe_USDT_DEX_ADDRESS = getDexAddress(15);
            uint256 fee_ = getTradingFees(15); // Fetch Current fee: 0.02%
            IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // eBTC-cbBTC DEX (Smart Collateral Only)
            address eBTC_cbBTC_DEX_ADDRESS = getDexAddress(16);
            uint256 fee_ = getTradingFees(16); // Fetch Current fee: 0.05%
            IFluidDex(eBTC_cbBTC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // LBTC-cbBTC DEX (Smart Collateral Only)
            address LBTC_cbBTC_DEX_ADDRESS = getDexAddress(17);
            uint256 fee_ = getTradingFees(17); // Fetch Current fee: 0.05%
            IFluidDex(LBTC_cbBTC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // USDe-USDT DEX (Smart Collateral Only)
            address USDe_USDT_DEX_ADDRESS = getDexAddress(18);
            uint256 fee_ = getTradingFees(18); // Fetch Current fee: 0.01%
            IFluidDex(USDe_USDT_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // deUSD-USDC DEX (Smart Collateral Only)
            address deUSD_USDC_DEX_ADDRESS = getDexAddress(19);
            uint256 fee_ = getTradingFees(19); // Fetch Current fee: 0.01%
            IFluidDex(deUSD_USDC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // USR-USDC DEX (Smart Collateral Only)
            address USR_USDC_DEX_ADDRESS = getDexAddress(20);
            uint256 fee_ = getTradingFees(20); // Fetch Current fee: 0.01%
            IFluidDex(USR_USDC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // ezETH-ETH DEX (Smart Collateral Only)
            address ezETH_ETH_DEX_ADDRESS = getDexAddress(21);
            uint256 fee_ = getTradingFees(21); // Fetch Current fee: 0.05%
            IFluidDex(ezETH_ETH_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // cbBTC-USDT DEX (Smart Collateral & Smart Debt)
            address cbBTC_USDT_DEX_ADDRESS = getDexAddress(22);
            uint256 fee_ = getTradingFees(22); // Fetch Current fee: 0.05%
            IFluidDex(cbBTC_USDT_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // USD0-USDC DEX (Smart Collateral Only)
            address USD0_USDC_DEX_ADDRESS = getDexAddress(23);
            uint256 fee_ = getTradingFees(23); // Fetch Current fee: 0.01%
            IFluidDex(USD0_USDC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

        {
            // fxUSD-USDC DEX (Smart Collateral Only)
            address fxUSD_USDC_DEX_ADDRESS = getDexAddress(24);
            uint256 fee_ = getTradingFees(24); // Fetch Current fee: 0.01%
            IFluidDex(fxUSD_USDC_DEX_ADDRESS).updateFeeAndRevenueCut(
                fee_,
                0.25 * fee_
            );
        }

    }

    // @notice Action 2: Add USDe-USDT Dex Fee auth
    function action2() internal isActionSkippable(2) {
        address USDe_USDT_DEX = getDexAddress(18);

        // Fee Handler Addresses
        address FeeHandler = address(0); // <update address>

        // Add new handler as auth
        DEX_FACTORY.setDexAuth(USDe_USDT_DEX, FeeHandler, true);
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
