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

contract PayloadIGP99 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 99;

    function execute() public virtual override {
        super.execute();

        // Action 1: Remove MS as auth and Set rebalancer for iUSD-USDe DEX
        action1();

        // Action 2: Update Range for cbBTC-wBTC DEX
        action2();

        // Action 3: Update Borrow Limits for sUSDe-GHO T1 vault
        action3();

        // Action 4: Increase Limits for USDC-USDT-CONCENTRATED DEX Vaults
        action4();

        // Action 5: Set limits for fUSDTb and update rate curve for USDTb
        action5();

        // Action 6: Remove center price for USDC-USDT and WBTC-cbBTC DEXes
        action6();

        // Action 7: Collect Revenue
        action7();

        // Action 8: Update Limits and Parameters for sUSDe-USDT, USDe-USDT, USDC-USDT DEXes
        action8();

        // Action 9: Update Limits for sUSDe-USDT, USDe-USDT based T2 and T4 vaults
        action9();

        // Action 10: Set Dust Limits for USDTb vaults
        action10();

        // Action 11: Set Dust Limits for USDE-USDTb DEX
        action11();
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

    // @notice Action 1: Remove MS as auth and Set rebalancer for iUSD-USDe DEX
    function action1() internal isActionSkippable(1) {
        {
            address fSL35_iUSD_USDe = getSmartLendingAddress(35);

            // set rebalancer at fSL31 to reserve contract proxy
            ISmartLendingAdmin(fSL35_iUSD_USDe).setRebalancer(
                address(FLUID_RESERVE)
            );
        }
        {
            address iUSD_USDe_DEX_ADDRESS = getDexAddress(35);
            DEX_FACTORY.setDexAuth(iUSD_USDe_DEX_ADDRESS, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 2: Update Range for cbBTC-wBTC DEX
    function action2() internal isActionSkippable(2) {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);
        {
            // update the upper and lower range +-0.2%
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(
                0.2 * 1e4,
                0.2 * 1e4,
                5 days
            );
        }
    }

    // @notice Action 3: Update Borrow Limits for sUSDe-GHO T1 vault
    function action3() internal isActionSkippable(3) {
        address sUSDe_GHO = getVaultAddress(56);

        // sUSDe-GHO T1 vault
        BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
            protocol: sUSDe_GHO,
            borrowToken: GHO_ADDRESS,
            expandPercent: 50 * 1e2, // 50%
            expandDuration: 6 hours, // 6 hours
            baseBorrowLimitInUSD: 20_000_000, // $20M base limit
            maxBorrowLimitInUSD: 100_000_000 // $100M max limit
        });

        setBorrowProtocolLimits(protocolConfig_);
    }

    // @notice Action 4: Increase Limits for USDC-USDT-CONCENTRATED DEX Vaults
    function action4() internal isActionSkippable(4) {
        {
            //sUSDe-USDT / USDT-USDC-CONCENTRATED
            address sUSDe_USDT_DEX_ADDRESS = getDexAddress(15);
            address sUSDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS = getVaultAddress(
                    126
                );

            {
                IFluidAdminDex.UserSupplyConfig[]
                    memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: sUSDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 5_000_000 * 1e18 // 5M shares
                });

                IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(
                    config_
                );
            }

            VAULT_FACTORY.setVaultAuth(
                sUSDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS,
                TEAM_MULTISIG,
                false
            );
        }

        {
            //USDe-USDT / USDT-USDC-CONCENTRATED
            address USDe_USDT_DEX_ADDRESS = getDexAddress(18);
            address USDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS = getVaultAddress(
                    127
                );

            {
                IFluidAdminDex.UserSupplyConfig[]
                    memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: USDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 5_000_000 * 1e18 // 5M shares
                });

                IFluidDex(USDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(
                    config_
                );
            }

            VAULT_FACTORY.setVaultAuth(
                USDe_USDT__USDT_USDC_CONCENTRATED_VAULT_ADDRESS,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 5: Set limits for fUSDTb and update rate curve for USDTb
    function action5() internal isActionSkippable(5) {
        {
            IFTokenAdmin fUSDTb_ADDRESS = IFTokenAdmin(
                address(F_USDTb_ADDRESS)
            );

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: address(fUSDTb_ADDRESS),
                supplyToken: USDTb_ADDRESS,
                expandPercent: 50% * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: 10_000_000 // $10M
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);

            // set rebalancer at fToken to reserve contract proxy
            IFTokenAdmin(F_USDTb_ADDRESS).updateRebalancer(
                0x264786EF916af64a1DB19F513F24a3681734ce92
            );
        }

        {
            AdminModuleStructs.RateDataV2Params[]
                memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

            params_[0] = AdminModuleStructs.RateDataV2Params({
                token: USDTb_ADDRESS, // USDTb
                kink1: 85 * 1e2, // 85%
                kink2: 93 * 1e2, // 93%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 1 * 1e2, // 1%
                rateAtUtilizationKink2: 5 * 1e2, // 5%
                rateAtUtilizationMax: 40 * 1e2 // 40%
            });

            LIQUIDITY.updateRateDataV2s(params_);
        }
    }

    // @notice Action 6: Remove center price for USDC-USDT and WBTC-cbBTC DEXes
    function action6() internal isActionSkippable(6) {
        address USDC_USDT_DEX = getDexAddress(2);
        address cbBTC_WBTC_DEX = getDexAddress(3);

        {
            // Remove center price by setting to address(0)
            IFluidDex(USDC_USDT_DEX).updateCenterPriceAddress(0, 1, 1);
        }

        {
            // Remove center price by setting to address(0)
            IFluidDex(cbBTC_WBTC_DEX).updateCenterPriceAddress(0, 1, 1);
        }
    }

    // @notice Action 7: Collect Revenue
    function action7() internal isActionSkippable(7) {
        {
            address[] memory tokens = new address[](5);

            tokens[0] = USDC_ADDRESS;
            tokens[1] = USDT_ADDRESS;
            tokens[2] = USDe_ADDRESS;
            tokens[3] = sUSDe_ADDRESS;
            tokens[4] = GHO_ADDRESS;

            LIQUIDITY.collectRevenue(tokens);
        }
        {
            address[] memory tokens = new address[](4);
            uint256[] memory amounts = new uint256[](4);

            tokens[0] = USDC_ADDRESS;
            amounts[0] =
                IERC20(USDC_ADDRESS).balanceOf(address(FLUID_RESERVE)) -
                10;

            tokens[1] = USDT_ADDRESS;
            amounts[1] =
                IERC20(USDT_ADDRESS).balanceOf(address(FLUID_RESERVE)) -
                10;

            tokens[2] = USDe_ADDRESS;
            amounts[2] =
                IERC20(USDe_ADDRESS).balanceOf(address(FLUID_RESERVE)) -
                10;

            tokens[3] = sUSDe_ADDRESS;
            amounts[3] =
                IERC20(sUSDe_ADDRESS).balanceOf(address(FLUID_RESERVE)) -
                10;

            FLUID_RESERVE.withdrawFunds(tokens, amounts, TEAM_MULTISIG);
        }
    }

    // @notice Action 8: Update Limits and Parameters for sUSDe-USDT, USDe-USDT, USDC-USDT DEXes
    function action8() internal isActionSkippable(8) {
        {
            // sUSDe-USDT DEX updates
            address sUSDe_USDT_DEX = getDexAddress(15);
            {
                // Set max sypply shares
                IFluidDex(sUSDe_USDT_DEX).updateMaxSupplyShares(
                    50_000_000 * 1e18 // from 37.5M shares
                );
            }
            {
                // Update Trading Fee
                IFluidDex(sUSDe_USDT_DEX).updateFeeAndRevenueCut(
                    0.01 * 1e4, // 0.01%
                    25 * 1e4 // 25%
                );
            }
            {
                // Update Range Percentages
                IFluidDex(sUSDe_USDT_DEX).updateRangePercents(
                    0.4 * 1e4, // +0.4%
                    0.8 * 1e4, // -0.8%
                    5 days
                );
            }
        }

        {
            // USDe-USDT DEX updates
            address USDe_USDT_DEX = getDexAddress(18);
            {
                // Set max supply shares
                IFluidDex(USDe_USDT_DEX).updateMaxSupplyShares(
                    25_000_000 * 1e18 // from 17.5M shares
                );
            }
        }

        {
            // USDC-USDT DEX updates
            address USDC_USDT_DEX = getDexAddress(2);
            {
                // Set max supply shares
                IFluidDex(USDC_USDT_DEX).updateMaxBorrowShares(
                    50_000_000 * 1e18 // from 35M shares
                );
            }
            {
                Dex memory DEX_USDC_USDT = Dex({
                    dex: USDC_USDT_DEX,
                    tokenA: USDC_ADDRESS,
                    tokenB: USDT_ADDRESS,
                    smartCollateral: false,
                    smartDebt: true,
                    baseWithdrawalLimitInUSD: 0, // $0
                    baseBorrowLimitInUSD: 40_000_000, // $40M
                    maxBorrowLimitInUSD: 120_000_000 // $120M
                });
                setDexLimits(DEX_USDC_USDT); // Smart Debt
            }
        }
    }

    // @notice Action 9: Update Limits for sUSDe-USDT, USDe-USDT based T2 and T4 vaults
    function action9() internal isActionSkippable(9) {
        {
            address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            VaultConfig memory VAULT_sUSDe_USDT__USDT = VaultConfig({
                vault: sUSDe_USDT__USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 17_500_000, // $17.5M
                maxBorrowLimitInUSD: 35_000_000 // $35M
            });

            setVaultLimits(VAULT_sUSDe_USDT__USDT);
        }

        {
            address USDe_USDT__USDT_VAULT = getVaultAddress(93);
            // [TYPE 2] USDe-USDT<>USDT | smart collateral & debt
            VaultConfig memory VAULT_USDe_USDT__USDT = VaultConfig({
                vault: USDe_USDT__USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 12_500_000, // $12.5M
                maxBorrowLimitInUSD: 25_000_000 // $25M
            });

            setVaultLimits(VAULT_USDe_USDT__USDT);
        }

        {
            // T4 sUSDe-USDT | USDC-USDT vault
            address USDC_USDT_DEX_ADDRESS = getDexAddress(2);
            address sUSDe_USDT__USDC_USDT_VAULT_ADDRESS = getVaultAddress(98);

            {
                // Increase sUSDe-USDT<>USDC-USDT vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: sUSDe_USDT__USDC_USDT_VAULT_ADDRESS,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 20_000_000 * 1e18, // 20M shares
                    maxDebtCeiling: 40_000_000 * 1e18 // 40M shares
                });

                IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(
                    config_
                );
            }
        }

        {
            // T4 USDe-USDT | USDC-USDT vault
            address USDC_USDT_DEX_ADDRESS = getDexAddress(2);
            address USDe_USDT__USDC_USDT_VAULT_ADDRESS = getVaultAddress(99);

            {
                // Increase USDe-USDT<>USDC-USDT vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: USDe_USDT__USDC_USDT_VAULT_ADDRESS,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 20_000_000 * 1e18, // 20M shares
                    maxDebtCeiling: 40_000_000 * 1e18 // 40M shares
                });

                IFluidDex(USDC_USDT_DEX_ADDRESS).updateUserBorrowConfigs(
                    config_
                );
            }
        }
    }

    // @notice Action 10: Set Dust Limits for USDTb vaults
    function action10() internal isActionSkippable(10) {
        {
            address ETH_USDTb_VAULT = getVaultAddress(128);

            // [TYPE 1] ETH/USDTb vault
            VaultConfig memory VAULT_ETH_USDTb = VaultConfig({
                vault: ETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: ETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000, // $7k
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_ETH_USDTb); // TYPE_1 => 128
            VAULT_FACTORY.setVaultAuth(ETH_USDTb_VAULT, TEAM_MULTISIG, true);
        }

        {
            address WSTETH_USDTb_VAULT = getVaultAddress(129);

            // [TYPE 1] WSTETH/USDTb vault
            VaultConfig memory VAULT_WSTETH_USDTb = VaultConfig({
                vault: WSTETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wstETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000, // $7k
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_WSTETH_USDTb); // TYPE_1 => 129
            VAULT_FACTORY.setVaultAuth(WSTETH_USDTb_VAULT, TEAM_MULTISIG, true);
        }

        {
            address WEETH_USDTb_VAULT = getVaultAddress(130);

            // [TYPE 1] WEETH/USDTb vault
            VaultConfig memory VAULT_WEETH_USDTb = VaultConfig({
                vault: WEETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: weETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000, // $7k
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_WEETH_USDTb); // TYPE_1 => 130
            VAULT_FACTORY.setVaultAuth(WEETH_USDTb_VAULT, TEAM_MULTISIG, true);
        }

        {
            address WBTC_USDTb_VAULT = getVaultAddress(131);

            // [TYPE 1] WBTC/USDTb vault
            VaultConfig memory VAULT_WBTC_USDTb = VaultConfig({
                vault: WBTC_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wBTC_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000, // $7k
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_WBTC_USDTb); // TYPE_1 => 131
            VAULT_FACTORY.setVaultAuth(WBTC_USDTb_VAULT, TEAM_MULTISIG, true);
        }

        {
            address CBBTC_USDTb_VAULT = getVaultAddress(132);

            // [TYPE 1] CBBTC/USDTb vault
            VaultConfig memory VAULT_CBBTC_USDTb = VaultConfig({
                vault: CBBTC_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: cbBTC_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000, // $7k
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_CBBTC_USDTb); // TYPE_1 => 132
            VAULT_FACTORY.setVaultAuth(CBBTC_USDTb_VAULT, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 11: Set Dust Limits for USDE-USDTb DEX
    function action11() internal isActionSkippable(11) {
        address USDE_USDTb_DEX = getDexAddress(36);
        {
            // USDE-USDTb DEX
            DexConfig memory DEX_USDE_USDTb = DexConfig({
                dex: USDE_USDTb_DEX,
                tokenA: USDe_ADDRESS,
                tokenB: USDTb_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_USDE_USDTb); // Smart Collateral

            DEX_FACTORY.setDexAuth(USDE_USDTb_DEX, TEAM_MULTISIG, true);
        }
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
            token == BOLD_ADDRESS ||
            token == iUSD_ADDRESS ||
            token == USDTb_ADDRESS
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
