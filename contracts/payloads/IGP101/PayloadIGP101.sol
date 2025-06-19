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

contract PayloadIGP101 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 101;

    function execute() public virtual override {
        super.execute();

        // Action 1: Withdraw $FLUID for USDC-ETH users
        action1();

        // Action 2: Set Launch Limits for USDTb DEX and its Smart Vaults
        action2();

        // Action 3: Pause USDe-USDT / USDTb Vault and remove auth
        action3();

        // Action 4: Set Launch Limits for wstUSR-USDC DEX and its vaults
        action4();

        // Action 5: Update CF, LT, LML and Borrow Cap for Gold Vaults
        action5();

        // Action 6: Update Borrow Cap for Gold DEX and Vaults
        action6();

        // Action 7: Set global authorization for DEX Factory
        action7();

        // Action 8: Set Launch Limits for GHO-USDe T4 Vault
        action8();

        // Action 9: Set Dust Limits for USDE-USDTb GHO T2 Vault
        action9();

        // Action 10: Set Dust Limits for GHO-USDe T2 Vault
        action10();

        // Action 11: Set Launch Limits for csUSDL/USDC DEX
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

    // @notice Action 1: Withdraw $FLUID for USDC-ETH users
    function action1() internal isActionSkippable(1) {
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string
            memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer FLUID to Team Multisig
        {
            uint256 FLUID_AMOUNT = 500_000 * 1e18; // 0.5 % of supply
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(
                withdrawSignature,
                FLUID_ADDRESS,
                FLUID_AMOUNT,
                TEAM_MULTISIG,
                0,
                0
            );
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    // @notice Action 2: Set Launch Limits for USDTb DEX and its Smart Vaults
    function action2() internal isActionSkippable(2) {
        {
            address USDE_USDTb_DEX = getDexAddress(36);

            // USDE-USDTb DEX
            DexConfig memory DEX_USDE_USDTb = DexConfig({
                dex: USDE_USDTb_DEX,
                tokenA: USDe_ADDRESS,
                tokenB: USDTb_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 9_000_000, // $9M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_USDE_USDTb); // Smart Collateral
        }
        {
            address USDE_USDTb__USDT_VAULT = getVaultAddress(137);

            // USDE-USDTb / USDT T2 vault
            VaultConfig memory VAULT_USDE_USDTb_USDT = VaultConfig({
                vault: USDE_USDTb__USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 20_000_000 // $20M
            });

            setVaultLimits(VAULT_USDE_USDTb_USDT);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDT_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
        {
            address USDE_USDTb__USDC_VAULT = getVaultAddress(138);

            // USDE-USDTb / USDC T2 vault
            VaultConfig memory VAULT_USDE_USDTb_USDC = VaultConfig({
                vault: USDE_USDTb__USDC_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 20_000_000 // $20M
            });

            setVaultLimits(VAULT_USDE_USDTb_USDC);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Pause USDe-USDT / USDTb Vault and remove auth
    function action3() internal isActionSkippable(3) {
        {
            address USDE_USDTb__USDTb_VAULT = getVaultAddress(136);
            // Pause borrow limits
            setBorrowProtocolLimitsPaused(
                USDE_USDTb__USDTb_VAULT,
                USDTb_ADDRESS
            );

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDTb_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 4: Set Launch Limits for wstUSR-USDC DEX and its vaults
    function action4() internal isActionSkippable(4) {
        {
            {
                address wstUSR_USDC_DEX = getDexAddress(27);

                // wstUSR-USDC DEX
                DexConfig memory DEX_wstUSR_USDC = DexConfig({
                    dex: wstUSR_USDC_DEX,
                    tokenA: wstUSR_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_wstUSR_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(wstUSR_USDC_DEX, TEAM_MULTISIG, false);
            }
            {
                address wstUSR_USDC__USDC_VAULT = getVaultAddress(133);
                // [TYPE 2] wstUSR-USDC<>USDC | smart collateral & debt
                VaultConfig memory VAULT_wstUSR_USDC_USDC = VaultConfig({
                    vault: wstUSR_USDC__USDC_VAULT,
                    vaultType: VAULT_TYPE.TYPE_2,
                    supplyToken: address(0),
                    borrowToken: USDC_ADDRESS,
                    baseWithdrawalLimitInUSD: 0,
                    baseBorrowLimitInUSD: 5_000_000, // $5M
                    maxBorrowLimitInUSD: 20_000_000 // $20M
                });

                setVaultLimits(VAULT_wstUSR_USDC_USDC); // TYPE_2 => 133
                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_VAULT,
                    TEAM_MULTISIG,
                    false
                );
            }
            {
                address wstUSR_USDC__USDC_USDT_VAULT = getVaultAddress(134);
                address USDC_USDT_DEX = getDexAddress(2);

                {
                    // Update wstUSR-USDC<>USDC-USDT vault borrow shares limit
                    IFluidAdminDex.UserBorrowConfig[]
                        memory config_ = new IFluidAdminDex.UserBorrowConfig[](
                            1
                        );
                    config_[0] = IFluidAdminDex.UserBorrowConfig({
                        user: wstUSR_USDC__USDC_USDT_VAULT,
                        expandPercent: 30 * 1e2, // 30%
                        expandDuration: 6 hours, // 6 hours
                        baseDebtCeiling: 2_500_000 * 1e18, // 2.5M shares ($5M)
                        maxDebtCeiling: 10_000_000 * 1e18 // 10M shares ($20M)
                    });

                    IFluidDex(USDC_USDT_DEX).updateUserBorrowConfigs(config_);
                }

                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_USDT_VAULT,
                    TEAM_MULTISIG,
                    false
                );
            }

            {
                address wstUSR_USDC__USDC_USDT_CONCENTRATED_VAULT = getVaultAddress(
                        135
                    );
                address USDC_USDT_CONCENTRATED_DEX = getDexAddress(34);

                {
                    // Update wstUSR-USDC<>USDC-USDT concentrated vault borrow shares limit
                    IFluidAdminDex.UserBorrowConfig[]
                        memory config_ = new IFluidAdminDex.UserBorrowConfig[](
                            1
                        );
                    config_[0] = IFluidAdminDex.UserBorrowConfig({
                        user: wstUSR_USDC__USDC_USDT_CONCENTRATED_VAULT,
                        expandPercent: 30 * 1e2, // 30%
                        expandDuration: 6 hours, // 6 hours
                        baseDebtCeiling: 2_500_000 * 1e18, // 2.5M shares ($5M)
                        maxDebtCeiling: 10_000_000 * 1e18 // 10M shares ($20M)
                    });

                    IFluidDex(USDC_USDT_CONCENTRATED_DEX)
                        .updateUserBorrowConfigs(config_);
                }

                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_USDT_CONCENTRATED_VAULT,
                    TEAM_MULTISIG,
                    false
                );
            }
        }
    }

    // @notice Action 5: Update CF, LT, LML for Gold Vaults
    function action5() internal isActionSkippable(5) {
        {
            address PAXG_XAUT__USDC_VAULT = getVaultAddress(122);
            address PAXG_XAUT__USDT_VAULT = getVaultAddress(123);
            address PAXG_XAUT__GHO_VAULT = getVaultAddress(124);
            address XAUT_USDC_VAULT = getVaultAddress(116);
            address XAUT_USDT_VAULT = getVaultAddress(117);
            address XAUT_GHO_VAULT = getVaultAddress(118);
            address PAXG_USDC_VAULT = getVaultAddress(119);
            address PAXG_USDT_VAULT = getVaultAddress(120);
            address PAXG_GHO_VAULT = getVaultAddress(121);

            uint256 LML = 90 * 1e2;
            uint256 LT = 80 * 1e2;
            uint256 CF = 75 * 1e2;

            IFluidVaultT1(PAXG_XAUT__USDC_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_XAUT__USDC_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_XAUT__USDC_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(PAXG_XAUT__USDT_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_XAUT__USDT_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_XAUT__USDT_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(PAXG_XAUT__GHO_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_XAUT__GHO_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_XAUT__GHO_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(XAUT_USDC_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(XAUT_USDC_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(XAUT_USDC_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(XAUT_USDT_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(XAUT_USDT_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(XAUT_USDT_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(XAUT_GHO_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(XAUT_GHO_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(XAUT_GHO_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(PAXG_USDC_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_USDC_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_USDC_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(PAXG_USDT_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_USDT_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_USDT_VAULT).updateCollateralFactor(CF);

            IFluidVaultT1(PAXG_GHO_VAULT).updateLiquidationMaxLimit(LML);
            IFluidVaultT1(PAXG_GHO_VAULT).updateLiquidationThreshold(LT);
            IFluidVaultT1(PAXG_GHO_VAULT).updateCollateralFactor(CF);
        }
    }

    // @notice Action 6: Update Borrow Cap for Gold DEX and Vaults
    function action6() internal isActionSkippable(6) {
        // PAXG-XAUT DEX
        address PAXG_XAUT_DEX = getDexAddress(32);
        {
            DexConfig memory DEX_PAXG_XAUT = DexConfig({
                dex: PAXG_XAUT_DEX,
                tokenA: PAXG_ADDRESS,
                tokenB: XAUT_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_PAXG_XAUT); // Smart Collateral
        }
        {
            // [TYPE 1] XAUT / USDC VAULT
            address XAUT_USDC_VAULT = getVaultAddress(116);
            {
                VaultConfig memory VAULT_XAUT_USDC = VaultConfig({
                    vault: XAUT_USDC_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: XAUT_ADDRESS,
                    borrowToken: USDC_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 1_500_000, // $1.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_XAUT_USDC); // TYPE_1 => 116
            }
        }

        {
            // [TYPE 1] XAUT / USDT VAULT
            address XAUT_USDT_VAULT = getVaultAddress(117);
            {
                VaultConfig memory VAULT_XAUT_USDT = VaultConfig({
                    vault: XAUT_USDT_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: XAUT_ADDRESS,
                    borrowToken: USDT_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 1_500_000, // $1.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_XAUT_USDT); // TYPE_1 => 117

            }
        }

        {
            // [TYPE 1] XAUT / GHO VAULT
            address XAUT_GHO_VAULT = getVaultAddress(118);
            {
                VaultConfig memory VAULT_XAUT_GHO = VaultConfig({
                    vault: XAUT_GHO_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: XAUT_ADDRESS,
                    borrowToken: GHO_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 1_500_000, // $1.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_XAUT_GHO); // TYPE_1 => 118
            }
        }

        {
            // [TYPE 1] PAXG / USDC VAULT
            address PAXG_USDC_VAULT = getVaultAddress(119);
            {
                VaultConfig memory VAULT_PAXG_USDC = VaultConfig({
                    vault: PAXG_USDC_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: PAXG_ADDRESS,
                    borrowToken: USDC_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 2_500_000, // $2.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_USDC); // TYPE_1 => 119
            }
        }

        {
            // [TYPE 1] PAXG / USDT VAULT
            address PAXG_USDT_VAULT = getVaultAddress(120);
            {
                VaultConfig memory VAULT_PAXG_USDT = VaultConfig({
                    vault: PAXG_USDT_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: PAXG_ADDRESS,
                    borrowToken: USDT_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 2_500_000, // $2.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_USDT); // TYPE_1 => 120
            }
        }

        {
            // [TYPE 1] PAXG / GHO VAULT
            address PAXG_GHO_VAULT = getVaultAddress(121);
            {
                VaultConfig memory VAULT_PAXG_GHO = VaultConfig({
                    vault: PAXG_GHO_VAULT,
                    vaultType: VAULT_TYPE.TYPE_1,
                    supplyToken: PAXG_ADDRESS,
                    borrowToken: GHO_ADDRESS,
                    baseWithdrawalLimitInUSD: 5_000_000, // $5M
                    baseBorrowLimitInUSD: 2_500_000, // $2.5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_GHO); // TYPE_1 => 121
            }
        }
        {
            // [TYPE 2] PAXG-XAUT<>USDC | smart collateral & normal debt
            address PAXG_XAUT__USDC_VAULT = getVaultAddress(122);

            {
                VaultConfig memory VAULT_PAXG_XAUT__USDC = VaultConfig({
                    vault: PAXG_XAUT__USDC_VAULT,
                    vaultType: VAULT_TYPE.TYPE_2,
                    supplyToken: address(0),
                    borrowToken: USDC_ADDRESS,
                    baseWithdrawalLimitInUSD: 0,
                    baseBorrowLimitInUSD: 5_000_000, // $5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_XAUT__USDC); // TYPE_2 => 122
            }
        }

        {
            // [TYPE 2] PAXG-XAUT<>USDT | smart collateral & normal debt
            address PAXG_XAUT__USDT_VAULT = getVaultAddress(123);

            {
                VaultConfig memory VAULT_PAXG_XAUT__USDT = VaultConfig({
                    vault: PAXG_XAUT__USDT_VAULT,
                    vaultType: VAULT_TYPE.TYPE_2,
                    supplyToken: address(0),
                    borrowToken: USDT_ADDRESS,
                    baseWithdrawalLimitInUSD: 0,
                    baseBorrowLimitInUSD: 5_000_000, // $5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_XAUT__USDT); // TYPE_2 => 123
            }
        }

        {
            // [TYPE 2] PAXG-XAUT<>GHO | smart collateral & normal debt
            address PAXG_XAUT__GHO_VAULT = getVaultAddress(124);

            {
                VaultConfig memory VAULT_PAXG_XAUT__GHO = VaultConfig({
                    vault: PAXG_XAUT__GHO_VAULT,
                    vaultType: VAULT_TYPE.TYPE_2,
                    supplyToken: address(0),
                    borrowToken: GHO_ADDRESS,
                    baseWithdrawalLimitInUSD: 0,
                    baseBorrowLimitInUSD: 5_000_000, // $5M
                    maxBorrowLimitInUSD: 10_000_000 // $10M
                });

                setVaultLimits(VAULT_PAXG_XAUT__GHO); // TYPE_2 => 124
            }
        }
    }

    // @notice Action 7: Set global authorization for DEX Factory
    function action7() internal isActionSkippable(7) {
        address global_auth_address = 0xE3e18c563d11ced9B0c9cb8dD0284CF4442bC06a;
        DEX_FACTORY.setGlobalAuth(global_auth_address, true);
    }

    // @notice Action 8: Set Launch Limits for GHO-USDe T4 Vault
    function action8() internal isActionSkippable(8) {
        {
            address GHO_USDe_DEX = getDexAddress(37);
            // GHO-USDe DEX
            DexConfig memory DEX_GHO_USDe = DexConfig({
                dex: GHO_USDe_DEX,
                tokenA: GHO_ADDRESS,
                tokenB: USDe_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_GHO_USDe); // Smart Collateral
        }
        {
            address GHO_USDe__GHO_USDC_VAULT = getVaultAddress(139);
            address GHO_USDC_DEX = getDexAddress(4);

            {
                // Update GHO-USDe<>GHO-USDC vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: GHO_USDe__GHO_USDC_VAULT,
                    expandPercent: 30 * 1e2, // 20%
                    expandDuration: 6 hours, // 12 hours
                    baseDebtCeiling: 5_000_000 * 1e18, // 5M shares ($10M)
                    maxDebtCeiling: 10_000_000 * 1e18 // 10M shares ($20M)
                });

                IFluidDex(GHO_USDC_DEX).updateUserBorrowConfigs(config_);
            }

            VAULT_FACTORY.setVaultAuth(
                GHO_USDe__GHO_USDC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 9: Set Dust Limits for USDE-USDTb GHO T2 Vault
    function action9() internal isActionSkippable(9) {
        {
            // dust limits
            address USDE_USDTb__GHO_VAULT = getVaultAddress(140);

            // USDE-USDTb / GHO T2 vault
            VaultConfig memory VAULT_USDE_USDTb_GHO = VaultConfig({
                vault: USDE_USDTb__GHO_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0), // supply token
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDE_USDTb_GHO);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__GHO_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 10: Set Dust Limits for GHO-USDe T2 Vault
    function action10() internal isActionSkippable(10) {
        {
            // dust limits
            address GHO_USDe__GHO_VAULT = getVaultAddress(141);

            // GHO-USDe / GHO T2 vault
            VaultConfig memory VAULT_GHO_USDe_GHO = VaultConfig({
                vault: GHO_USDe__GHO_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0), // supply token
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_GHO_USDe_GHO);

            VAULT_FACTORY.setVaultAuth(
                GHO_USDe__GHO_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 11: Set Launch Limits for csUSDL/USDC DEX
    function action11() internal isActionSkippable(11) {
        address csUSDL_USDC_DEX = getDexAddress(38);
        {
            // csUSDL-USDC DEX
            {
                // csUSDL-USDC Dex
                DexConfig memory DEX_csUSDL_USDC = DexConfig({
                    dex: csUSDL_USDC_DEX,
                    tokenA: csUSDL_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 9_000_000, // $9M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_csUSDL_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(csUSDL_USDC_DEX, TEAM_MULTISIG, true);
            }
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
        } else if (token == csUSDL_ADDRESS) {
            usdPrice = csUSDL_USD_PRICE;
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
