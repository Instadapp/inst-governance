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
import {IFluidLendingFactory} from "../common/interfaces/IFluidLendingFactory.sol";

import {ICodeReader} from "../common/interfaces/ICodeReader.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";
import {PayloadIGPMain} from "../common/main.sol";

contract PayloadIGP95 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 95;

    function execute() public virtual override {
        super.execute();

        // Action 1: Set launch limits for sUSDe-GHO/USDC-GHO T4 vault
        action1();

        // Action 2: Update Range Percent for sUSDS<>USDT DEX
        action2();

        // Action 3: Update Max Borrow Limits for Deprecated DEXes
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

    // @notice Action 1: Set launch limits for sUSDe-GHO/USDC-GHO T4 vault
    function action1() internal isActionSkippable(1) {
        {
            //sUSDe-GHO / USDC-GHO
            address sUSDe_GHO_DEX_ADDRESS = getDexAddress(33);
            address USDC_GHO_DEX_ADDRESS = getDexAddress(4);
            address sUSDe_GHO__USDC_GHO_VAULT_ADDRESS = getVaultAddress(125);

            {
                // Update sUSDe-GHO<>USDC-GHO vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                    expandPercent: 30 * 1e2, // 30%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 4_000_000 * 1e18, // 4M shares ($8M)
                    maxDebtCeiling: 5_000_000 * 1e18 // 5M shares ($10M)
                });

                IFluidDex(USDC_GHO_DEX_ADDRESS).updateUserBorrowConfigs(
                    config_
                );
            }

            VAULT_FACTORY.setVaultAuth(
                sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 2: Update Range Percent for sUSDS<>USDT DEX
    function action2() internal isActionSkippable(2) {
        address SUSDS_USDT_DEX_ADDRESS = getDexAddress(31);

        IFluidDex(SUSDS_USDT_DEX_ADDRESS).updateRangePercents(
            0.15 * 1e4, // upper range: 0.15% - same
            0.01 * 1e4, // lower range: 0.01%
            0 // instant
        );
    }

    // @notice Action 3: Update Max Borrow Limits for Deprecated DEXes
    function action3() internal isActionSkippable(3) {
        address USDC_ETH_DEX = getDexAddress(5);
        {
            // USDC-ETH DEX
            {
                // USDC-ETH Dex
                DexConfig memory DEX_USDC_ETH = DexConfig({
                    dex: USDC_ETH_DEX,
                    tokenA: USDC_ADDRESS,
                    tokenB: ETH_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 1_020 // 0.4 ETH
                });
                setDexLimits(DEX_USDC_ETH); // Smart Collateral and Smart Debt
            }
        }
    }

    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 2_400 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 2_950 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_600 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 2_550 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 2_500 * 1e2;
    uint256 public constant mETH_USD_PRICE = 2_590 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 2_550 * 1e2;

    uint256 public constant BTC_USD_PRICE = 103_500 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 5 * 1e2;

    uint256 public constant RLP_USD_PRICE = 1.16 * 1e2;
    uint256 public constant wstUSR_USD_PRICE = 1.07 * 1e2;
    uint256 public constant XAUT_USD_PRICE = 3_350 * 1e2;
    uint256 public constant PAXG_USD_PRICE = 3_350 * 1e2;

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
        } else if (token == XAUT_ADDRESS) {
            usdPrice = XAUT_USD_PRICE;
            decimals = 6;
        } else if (token == PAXG_ADDRESS) {
            usdPrice = PAXG_USD_PRICE;
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
