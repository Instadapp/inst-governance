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

        // Action 3: Set Launch Limits for USDe-USDT / USDTb Vault
        action3();

        // Action 4: Set Launch Limits for wstUSR-USDC DEX and its vaults and its vaults
        action4();

        // Action 5: Update CF, LT, LML and Borrow Cap for Gold Smart Vaults
        action5();

        // Action 6: Update Borrow Cap for Gold DEX
        action6();

        // Action 7: Set global authorization for DEX Factory
        action7();

        // Action 8: Set Launch Limits for GHO-USDe T4 Vault
        action8();

        // Action 9: Increase Borrow Cap on GHO-USDC DEX
        action9();

        // Action 10: Increase Borrow Cap on USDC-USDT DEX
        action10();
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
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_USDE_USDTb); // Smart Collateral

            DEX_FACTORY.setDexAuth(USDE_USDTb_DEX, TEAM_MULTISIG, false);
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

    // @notice Action 3: Set Launch Limits for USDe-USDT / USDTb Vault
    function action3() internal isActionSkippable(3) {
        {
            address USDE_USDTb__USDTb_VAULT = getVaultAddress(136);
            // Pause borrow limits
            setBorrowProtocolLimitsPaused(USDE_USDTb__USDTb_VAULT, USDTb_ADDRESS);
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
                    maxBorrowLimitInUSD: 10_000_000 // $10M
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
                        expandPercent: 30 * 1e2, // 20%
                        expandDuration: 6 hours, // 12 hours
                        baseDebtCeiling: 2_500_000 * 1e18, // 2.5M shares ($5M)
                        maxDebtCeiling: 5_000_000 * 1e18 // 5M shares ($10M)
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
                        expandPercent: 30 * 1e2, // 20%
                        expandDuration: 6 hours, // 12 hours
                        baseDebtCeiling: 2_500_000 * 1e18, // 2.5M shares ($5M)
                        maxDebtCeiling: 5_000_000 * 1e18 // 5M shares ($10M)
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

    // @notice Action 5: Update CF, LT, LML for Gold Smart Vaults
    function action5() internal isActionSkippable(5) {
        {
            address PAXG_XAUT__USDC_VAULT = getVaultAddress(122);
            address PAXG_XAUT__USDT_VAULT = getVaultAddress(123);
            address PAXG_XAUT__GHO_VAULT = getVaultAddress(124);

            uint256 LML = 83 * 1e2;
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
        }
    }

    // @notice Action 6: Update Borrow Cap for Gold DEX
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
                IFluidDex(PAXG_XAUT_DEX).updateMaxSupplyShares(
                    725 * 1e18 // $5M
                );
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
                baseWithdrawalLimitInUSD: 8_100_000, // $8.1M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_GHO_USDe); // Smart Collateral

            DEX_FACTORY.setDexAuth(GHO_USDe_DEX, TEAM_MULTISIG, false);
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

    // @notice Action 9: Increase Borrow Cap on GHO-USDC DEX
    function action9() internal isActionSkippable(9) {
        address GHO_USDC_DEX = getDexAddress(4);
        {
            // Increase GHO-USDC Dex Pool Limits
            DexConfig memory DEX_GHO_USDC = DexConfig({
                dex: GHO_USDC_DEX,
                tokenA: GHO_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 11_000_000, // $11M
                baseBorrowLimitInUSD: 30_000_000, // $30M
                maxBorrowLimitInUSD: 50_000_000 // $50M
            });
            setDexLimits(DEX_GHO_USDC); // Smart Collateral & Smart Debt
        }
        {
            IFluidDex(GHO_USDC_DEX).updateMaxBorrowShares(20_000_000 * 1e18); // from 16M shares
        }
    }

    // @notice Action 10: Increase Borrow Cap on USDC-USDT normal and concentrated DEXes
    function action10() internal isActionSkippable(10) {
        address USDC_USDT_DEX = getDexAddress(2);
        {
            // Increase USDC-USDT Dex Pool Limits
            DexConfig memory DEX_USDC_USDT = DexConfig({
                dex: USDC_USDT_DEX,
                tokenA: USDC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: false,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 75_000_000, // $75M
                maxBorrowLimitInUSD: 125_000_000 // $125M
            });
            setDexLimits(DEX_USDC_USDT); // Smart Collateral & Smart Debt
        }
        {
            IFluidDex(USDC_USDT_DEX).updateMaxBorrowShares(55_000_000 * 1e18); // from 50M shares
        }

        address USDC_USDT_CONCENTRATED_DEX = getDexAddress(34);
        {
            // Increase USDC-USDT-CONCENTRATED Dex Pool Limits
            DexConfig memory DEX_USDC_USDT_CONCENTRATED = DexConfig({
                dex: USDC_USDT_CONCENTRATED_DEX,
                tokenA: USDC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: false,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 22_000_000, // $22M
                maxBorrowLimitInUSD: 37_000_000 // $37M
            });
            setDexLimits(DEX_USDC_USDT_CONCENTRATED); // Smart Debt
        }
        {
            IFluidDex(USDC_USDT_CONCENTRATED_DEX).updateMaxBorrowShares(15_000_000 * 1e18); // from 10M shares
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
