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

contract PayloadIGP93 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 93;

    function execute() public virtual override {
        super.execute();

        // Action 1: Collect ETH Revenue and Transfer to Multisig
        action1();

        // Action 2: Update Borrow Rate Magnifier on LBTC-CBBTC / WBTC Vault 
        action2();

        // Action 3: Adjust Rate curves of WBTC & cbBTC
        action3();

        // Action 4: Adjust CF, LT, LML for GHO Vaults
        action4();

        // Action 5: Set dust limits for new GHO DEXes
        action5();

        // Action 6: Set dust limits for GHO T4 vaults
        action6();

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


    // @notice Action 1: Collect ETH Revenue and Transfer to Multisig
    function action1() internal isActionSkippable(1) {
        address[] memory tokens = new address[](1);

        tokens[0] = ETH_ADDRESS;

        LIQUIDITY.collectRevenue(tokens);

        uint256[] memory amounts = new uint256[](1);

        amounts[0] = 128 ether; // 129 ETH in reserves - 1

        FLUID_RESERVE.withdrawFunds(tokens, amounts, TEAM_MULTISIG);
    }

    // @notice Action 2: Update Borrow Rate Magnifier on LBTC-CBBTC / WBTC Vault 
    function action2() internal isActionSkippable(2) {
        address lBTC_cbBTC__WBTC_VAULT = getVaultAddress(97);

        IFluidVaultT1(lBTC_cbBTC__WBTC_VAULT).updateBorrowRateMagnifier(150 * 1e2); // 1.5x borrowRateMagnifier
    }

    // @notice Action 3: Adjust Rate curves of WBTC & cbBTC
    function action3() internal isActionSkippable(3) {
        {
            // Update WBTC & cbBTC rate
            FluidLiquidityAdminStructs.RateDataV2Params[]
                memory params_ = new FluidLiquidityAdminStructs.RateDataV2Params[](
                    2
                );

            params_[0] = FluidLiquidityAdminStructs.RateDataV2Params({
                token: WBTC_ADDRESS, // WBTC
                kink1: 80 * 1e2, // 80%
                kink2: 90 * 1e2, // 90%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 2 * 1e2, // 2%
                rateAtUtilizationKink2: 10 * 1e2, // 10%
                rateAtUtilizationMax: 100 * 1e2 // 100%
            });

            params_[1] = FluidLiquidityAdminStructs.RateDataV2Params({
                token: cbBTC_ADDRESS, // cbBTC
                kink1: 80 * 1e2, // 80%
                kink2: 90 * 1e2, // 90%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 2 * 1e2, // 2%
                rateAtUtilizationKink2: 10 * 1e2, // 10%
                rateAtUtilizationMax: 100 * 1e2 // 100%
            });

            LIQUIDITY.updateRateDataV2s(params_);
        }
    }

    // @notice Action 4: Adjust CF, LT, LML for GHO Vaults
    function action4() internal isActionSkippable(4) {
        {
            address GHO_USDC__GHO_USDC = getVaultAddress(61);
            address sUSDe_GHO = getVaultAddress(56);

            uint256 CF = 90 * 1e2;
            uint256 LT = 92 * 1e2;
            uint256 LML = 95 * 1e2;

            IFluidVaultT1(GHO_USDC__GHO_USDC).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(GHO_USDC__GHO_USDC).updateLiquidationThreshold(LT);
            IFluidVaultT1(GHO_USDC__GHO_USDC).updateCollateralFactor(CF);

            IFluidVaultT1(sUSDe_GHO).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(sUSDe_GHO).updateLiquidationThreshold(LT);
            IFluidVaultT1(sUSDe_GHO).updateCollateralFactor(CF);
        }

        {
            address ETH_GHO = getVaultAddress(54);

            uint256 CF = 87 * 1e2;
            uint256 LT = 92 * 1e2;
            uint256 LML = 94 * 1e2;

            IFluidVaultT1(ETH_GHO).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(ETH_GHO).updateLiquidationThreshold(LT);
            IFluidVaultT1(ETH_GHO).updateCollateralFactor(CF);
        }
    }

        // @notice Action 5: Set dust limits for new GHO DEXes
    function action5() internal isActionSkippable(5) {
        {
            address sUSDe_GHO_DEX = getDexAddress(32);
            {
                // sUSDe-GHO DEX
                {
                    // sUSDe-GHO Dex
                    Dex memory DEX_sUSDe_GHO = Dex({
                        dex: sUSDe_GHO_DEX,
                        tokenA: sUSDe_ADDRESS,
                        tokenB: GHO_ADDRESS,
                        smartCollateral: true,
                        smartDebt: false,
                        baseWithdrawalLimitInUSD: 10_000, // $10k
                        baseBorrowLimitInUSD: 0, // $0
                        maxBorrowLimitInUSD: 0 // $0
                    });
                    setDexLimits(DEX_sUSDe_GHO); // Smart Collateral

                    DEX_FACTORY.setDexAuth(sUSDe_GHO_DEX, TEAM_MULTISIG, true);
                }
            }
        }

        {
            address USDT_GHO_DEX = getDexAddress(33);
            {
                // USDT-GHO DEX
                {
                    // USDT-GHO Dex
                    Dex memory DEX_USDT_GHO = Dex({
                        dex: USDT_GHO_DEX,
                        tokenA: USDT_ADDRESS,
                        tokenB: GHO_ADDRESS,
                        smartCollateral: false,
                        smartDebt: true,
                        baseWithdrawalLimitInUSD: 0, // $0
                        baseBorrowLimitInUSD: 10_000, // $10k
                        maxBorrowLimitInUSD: 10_000 // $10k
                    });
                    setDexLimits(DEX_USDT_GHO); // Smart Debt

                    DEX_FACTORY.setDexAuth(USDT_GHO_DEX, TEAM_MULTISIG, true);
                }
            }
        }

        {
            address USDC_GHO_DEX = getDexAddress(34);
            {
                // USDC-GHO DEX
                {
                    // USDC-GHO Dex
                    Dex memory DEX_USDC_GHO = Dex({
                        dex: USDC_GHO_DEX,
                        tokenA: USDC_ADDRESS,
                        tokenB: GHO_ADDRESS,
                        smartCollateral: false,
                        smartDebt: true,
                        baseWithdrawalLimitInUSD: 0, // $0
                        baseBorrowLimitInUSD: 10_000, // $10k
                        maxBorrowLimitInUSD: 10_000 // $10k
                    });
                    setDexLimits(DEX_USDC_GHO); // Smart Debt

                    DEX_FACTORY.setDexAuth(USDC_GHO_DEX, TEAM_MULTISIG, true);
                }
            }
        }

        {
            address USDe_GHO_DEX = getDexAddress(35);
            {
                // USDe-GHO DEX
                {
                    // USDe-GHO Dex
                    Dex memory DEX_USDe_GHO = Dex({
                        dex: USDe_GHO_DEX,
                        tokenA: USDe_ADDRESS,
                        tokenB: GHO_ADDRESS,
                        smartCollateral: true,
                        smartDebt: false,
                        baseWithdrawalLimitInUSD: 10_000, // $10k
                        baseBorrowLimitInUSD: 0, // $0
                        maxBorrowLimitInUSD: 0 // $0
                    });
                    setDexLimits(DEX_USDe_GHO); // Smart Collateral

                    DEX_FACTORY.setDexAuth(USDe_GHO_DEX, TEAM_MULTISIG, true);
                }
            }
        }
    }

    // @notice Action 6: Set dust limits for GHO T4 vaults
    function action6() internal isActionSkippable(6) {
        {
            // sUSDe/GHO : USDT/GHO
            address sUSDe_GHO_DEX_ADDRESS = getDexAddress(32);
            address USDT_GHO_DEX_ADDRESS = getDexAddress(33);
            address sUSDe_GHO__USDT_GHO_VAULT_ADDRESS = getVaultAddress(116);

            {
                // Update sUSDe-GHO<>USDT-GHO vault supply shares limit
                IFluidAdminDex.UserSupplyConfig[]
                    memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: sUSDe_GHO__USDT_GHO_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(sUSDe_GHO_DEX_ADDRESS).updateUserSupplyConfigs(config_);
            }

            {
                // Update sUSDe-GHO<>USDT-GHO vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: sUSDe_GHO__USDT_GHO_VAULT_ADDRESS,
                    expandPercent: 30 * 1e2, // 30%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                    maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(USDT_GHO_DEX_ADDRESS).updateUserBorrowConfigs(config_);
            }

            VAULT_FACTORY.setVaultAuth(
                sUSDe_GHO__USDT_GHO_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }

        {
            //sUSDe/GHO : USDC/GHO
            address sUSDe_GHO_DEX_ADDRESS = getDexAddress(32);
            address USDC_GHO_DEX_ADDRESS = getDexAddress(34);
            address sUSDe_GHO__USDC_GHO_VAULT_ADDRESS = getVaultAddress(117);

            {
                // Update sUSDe-GHO<>USDC-GHO vault supply shares limit
                IFluidAdminDex.UserSupplyConfig[]
                    memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(sUSDe_GHO_DEX_ADDRESS).updateUserSupplyConfigs(config_);
            }

            {
                // Update sUSDe-GHO<>USDC-GHO vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                    expandPercent: 30 * 1e2, // 30%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                    maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(USDC_GHO_DEX_ADDRESS).updateUserBorrowConfigs(config_);
            }

            VAULT_FACTORY.setVaultAuth(
                sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }

        {
            //USDe/GHO : USDT/GHO
            address USDe_GHO_DEX_ADDRESS = getDexAddress(35);
            address USDT_GHO_DEX_ADDRESS = getDexAddress(33);
            address USDe_GHO__USDT_GHO_VAULT_ADDRESS = getVaultAddress(118);

            {
                // Update USDe-GHO<>USDT-GHO vault supply shares limit
                IFluidAdminDex.UserSupplyConfig[]
                    memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: USDe_GHO__USDT_GHO_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(USDe_GHO_DEX_ADDRESS).updateUserSupplyConfigs(config_);
            }

            {
                // Update USDe-GHO<>USDT-GHO vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: USDe_GHO__USDT_GHO_VAULT_ADDRESS,
                    expandPercent: 30 * 1e2, // 30%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                    maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(USDT_GHO_DEX_ADDRESS).updateUserBorrowConfigs(config_);
            }

            VAULT_FACTORY.setVaultAuth(
                USDe_GHO__USDT_GHO_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }

    }

    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 1_600 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 2_300 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 1_975 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 1_930 * 1e2;
    uint256 public constant mETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 1_975 * 1e2;

    uint256 public constant BTC_USD_PRICE = 82_000 * 1e2;

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
