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

contract PayloadIGP96 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 96;

    function execute() public virtual override {
        super.execute();

        // Action 1: Update Range Percent for sUSDS<>USDT DEX
        action1();

        // Action 2: Update Max Borrow Limits for Deprecated DEXes
        action2();

        // Action 3: Remove Team MS as Auth on XAUT<>PAXG DEX
        action3();

        // Action 4: Update LT for cbBTC/stable, WBTC/stable Vaults
        action4();
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

    // @notice Action 1: Update Range Percent for sUSDS<>USDT DEX
    function action1() internal isActionSkippable(1) {
        address SUSDS_USDT_DEX_ADDRESS = getDexAddress(31);

        IFluidDex(SUSDS_USDT_DEX_ADDRESS).updateRangePercents(
            0.15 * 1e4, // upper range: same
            0.01 * 1e4, // lower range: 0.01%
            0 // instant
        );
    }

    // @notice Action 2: Update Max Borrow Limits for Deprecated DEXes
    function action2() internal isActionSkippable(2) {
        address USDC_ETH_DEX = getDexAddress(5);
        {
            // USDC-ETH DEX
            {
                {
                    // Set debt ceiling for USDC token
                    AdminModuleStructs.UserBorrowConfig[]
                        memory configsUSDC = new AdminModuleStructs.UserBorrowConfig[](
                            1
                        );

                    configsUSDC[0] = AdminModuleStructs.UserBorrowConfig({
                        user: USDC_ETH_DEX,
                        token: USDC_ADDRESS,
                        mode: 1,
                        expandPercent: 1,
                        expandDuration: 16777215,
                        baseDebtCeiling: 1 * 1e6, // $1 in USDC
                        maxDebtCeiling: 1000 * 1e6 // $1000 in USDC
                    });

                    LIQUIDITY.updateUserBorrowConfigs(configsUSDC);
                }

                {
                    // Set debt ceiling for ETH token
                    AdminModuleStructs.UserBorrowConfig[]
                        memory configsETH = new AdminModuleStructs.UserBorrowConfig[](
                            1
                        );

                    configsETH[0] = AdminModuleStructs.UserBorrowConfig({
                        user: USDC_ETH_DEX,
                        token: ETH_ADDRESS,
                        mode: 1,
                        expandPercent: 1,
                        expandDuration: 16777215,
                        baseDebtCeiling: 0.001 ether, // $1 in ETH
                        maxDebtCeiling: 0.4 ether // $1000 in ETH
                    });

                    LIQUIDITY.updateUserBorrowConfigs(configsETH);
                }
            }
        }
    }

    // @notice Action 3: Remove Team MS as Auth on XAUT<>PAXG DEX
    function action3() internal isActionSkippable(3) {
        address XAUT_PAXG_DEX = getDexAddress(32);

        DEX_FACTORY.setDexAuth(XAUT_PAXG_DEX, TEAM_MULTISIG, false);
    }

    // @notice Action 4: Update LT for cbBTC/stable, WBTC/stable Vaults
    function action4() internal isActionSkippable(4) {
        address wBTC_USDC_VAULT = getVaultAddress(21);
        address wBTC_USDT_VAULT = getVaultAddress(22);
        address wBTC_GHO_VAULT = getVaultAddress(59);
        address wBTC_USDe_VAULT = getVaultAddress(72);
        address cbBTC_USDC_VAULT = getVaultAddress(29);
        address cbBTC_USDT_VAULT = getVaultAddress(30);
        address cbBTC_GHO_VAULT = getVaultAddress(60);
        address cbBTC_USDe_VAULT = getVaultAddress(73);
        address cbBTC_SUSDS_VAULT = getVaultAddress(86);

        uint256 LT = 90 * 1e2;

        IFluidVaultT1(wBTC_USDC_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(wBTC_USDT_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(wBTC_GHO_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(wBTC_USDe_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(cbBTC_USDC_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(cbBTC_USDT_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(cbBTC_GHO_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(cbBTC_USDe_VAULT).updateLiquidationThreshold(LT);
        IFluidVaultT1(cbBTC_SUSDS_VAULT).updateLiquidationThreshold(LT);
    }

    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 2_500 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_050 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_700 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 2_650 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 2_600 * 1e2;
    uint256 public constant mETH_USD_PRICE = 2_690 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 2_650 * 1e2;

    uint256 public constant BTC_USD_PRICE = 103_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.17 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.05 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 4.2 * 1e2;

    uint256 public constant RLP_USD_PRICE = 1.18 * 1e2;
    uint256 public constant wstUSR_USD_PRICE = 1.07 * 1e2;
    uint256 public constant XAUT_USD_PRICE = 3_240 * 1e2;
    uint256 public constant PAXG_USD_PRICE = 3_240 * 1e2;

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
