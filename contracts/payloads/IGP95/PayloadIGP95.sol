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

        // Action 1: Set dust limits for sUSDe-GHO and USDC-GHO DEXes
        action1();

        // Action 2: Set dust limits for sUSDe-GHO/USDC-GHO T4 vault
        action2();

        // Action 3: Reduce allowance of fUSDC and fUSDT
        action3();

        // Action 4: Remove Borrow Rewards handlers as Vault Auth
        action4();

        // Action 5: Remove Team Multisig as Auth on Unlaunched Vaults
        action5();

        // Action 6: Pause Limits for Unlaunched USDe Collateral Vaults
        action6();

        // Action 7: Pause Limits for Bugged DEXes
        action7();

        // Action 8: Set Launch Limits for RLP-USDC DEX
        action8();

        // Action 9: Set Launch Limits for Gold Vaults and DEX
        action9();

        // Action 10: Update Borrow Limits for sUSDe/USDC
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

    // @notice Action 1: Set dust limits for sUSDe-GHO DEXes
    function action1() internal isActionSkippable(1) {
        {
            address sUSDe_GHO_DEX = getDexAddress(33);
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
    }

    // @notice Action 2: Set dust limits for sUSDe-GHO/USDC-GHO T4 vault
    function action2() internal isActionSkippable(2) {
        {
            //sUSDe/GHO : USDC/GHO
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
                    baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                    maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(USDC_GHO_DEX_ADDRESS).updateUserBorrowConfigs(
                    config_
                );
            }

            VAULT_FACTORY.setVaultAuth(
                sUSDe_GHO__USDC_GHO_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 3: Reduce allowance of fUSDC and fUSDT
    function action3() internal isActionSkippable(3) {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        {
            /// fUSDC
            protocols[0] = F_USDC_ADDRESS;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = 1_200_000 * 1e6; // 1.2M
        }

        {
            /// fUSDT
            protocols[1] = F_USDT_ADDRESS;
            tokens[1] = USDT_ADDRESS;
            amounts[1] = 1_200_000 * 1e6; // 1.2M
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    // @notice Action 4: Remove Borrow Rewards handlers as Vault Auth
    function action4() internal isActionSkippable(4) {
        {
            address cbBTC_USDC = getVaultAddress(29);

            // Fee Handler Addresses
            address FeeHandler = 0x7110cED08f0E26c14a2eF7A980c4F17C70aBa7c0;

            // Remove handler as auth
            VAULT_FACTORY.setVaultAuth(cbBTC_USDC, FeeHandler, false);
        }

        {
            address cbBTC_USDT = getVaultAddress(30);

            // Fee Handler Addresses
            address FeeHandler = 0xf5fD6c6f936689018215CB10d7a5b99A43a39D28;

            // Remove handler as auth
            VAULT_FACTORY.setVaultAuth(cbBTC_USDT, FeeHandler, false);
        }

        {
            address wBTC_USDT = getVaultAddress(22);

            // Fee Handler Addresses
            address FeeHandler = 0x6D90d460929b921f6C74838a9d25CC69B486D605;

            // Remove handler as auth
            VAULT_FACTORY.setVaultAuth(wBTC_USDT, FeeHandler, false);
        }

        {
            address wBTC_USDC = getVaultAddress(21);

            // Fee Handler Addresses
            address FeeHandler = 0x5E5768B6b42c12dA8e75eb0AA6fD47Be33a5b24e;

            // Remove handler as auth
            VAULT_FACTORY.setVaultAuth(wBTC_USDC, FeeHandler, false);
        }
    }

    // @notice Action 5: Remove Team Multisig as Auth on Unlaunched Vaults
    function action5() internal isActionSkippable(5) {
        {
            address USDC_ETH__USDC_ETH = getVaultAddress(62);

            VAULT_FACTORY.setVaultAuth(
                USDC_ETH__USDC_ETH,
                TEAM_MULTISIG,
                false
            );
        }
        {
            address WBTC_ETH__WBTC_ETH = getVaultAddress(63);

            VAULT_FACTORY.setVaultAuth(
                WBTC_ETH__WBTC_ETH,
                TEAM_MULTISIG,
                false
            );
        }
        {
            address cbBTC_ETH__cbBTC_ETH = getVaultAddress(64);

            VAULT_FACTORY.setVaultAuth(
                cbBTC_ETH__cbBTC_ETH,
                TEAM_MULTISIG,
                false
            );
        }
        {
            address USDe_USDC__USDe_USDC = getVaultAddress(65);

            VAULT_FACTORY.setVaultAuth(
                USDe_USDC__USDe_USDC,
                TEAM_MULTISIG,
                false
            );
        }
        {
            address FLUID_ETH__ETH = getVaultAddress(75);

            VAULT_FACTORY.setVaultAuth(FLUID_ETH__ETH, TEAM_MULTISIG, false);
        }
        {
            address eBTC_cbBTC = getVaultAddress(95);

            VAULT_FACTORY.setVaultAuth(eBTC_cbBTC, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 6: Pause Limits for Unlaunched USDe Collateral Vaults
    function action6() internal isActionSkippable(6) {
        {
            address USDe_USDC = getVaultAddress(66);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(USDe_USDC, USDe_ADDRESS);
            setBorrowProtocolLimitsPaused(USDe_USDC, USDC_ADDRESS);
        }

        {
            address USDe_USDT = getVaultAddress(67);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(USDe_USDT, USDe_ADDRESS);
            setBorrowProtocolLimitsPaused(USDe_USDT, USDT_ADDRESS);
        }

        {
            address USDe_GHO = getVaultAddress(68);
            // Pause supply and borrow limits
            setSupplyProtocolLimitsPaused(USDe_GHO, USDe_ADDRESS);
            setBorrowProtocolLimitsPaused(USDe_GHO, GHO_ADDRESS);
        }
    }

    // @notice Action 7: Pause Limits for Bugged DEXes
    function action7() internal isActionSkippable(7) {
        {
            address USDC_ETH_DEX = getDexAddress(5);
            {
                // USDC-ETH DEX
                {
                    setSupplyProtocolLimitsPaused(USDC_ETH_DEX, USDC_ADDRESS);

                    setSupplyProtocolLimitsPaused(USDC_ETH_DEX, ETH_ADDRESS);
                }
                {
                    setBorrowProtocolLimitsPaused(USDC_ETH_DEX, USDC_ADDRESS);

                    setBorrowProtocolLimitsPaused(USDC_ETH_DEX, ETH_ADDRESS);
                }
            }

            {
                // Pause user supply and borrow
                address[] memory supplyTokens = new address[](2);
                supplyTokens[0] = USDC_ADDRESS;
                supplyTokens[1] = ETH_ADDRESS;

                address[] memory borrowTokens = new address[](2);
                borrowTokens[0] = USDC_ADDRESS;
                borrowTokens[1] = ETH_ADDRESS;

                // Pause the user operations
                LIQUIDITY.pauseUser(USDC_ETH_DEX, supplyTokens, borrowTokens);
            }
        }
        {
            address WBTC_ETH_DEX = getDexAddress(6);
            {
                // WBTC-ETH DEX
                {
                    setSupplyProtocolLimitsPaused(WBTC_ETH_DEX, WBTC_ADDRESS);

                    setSupplyProtocolLimitsPaused(WBTC_ETH_DEX, ETH_ADDRESS);
                }
                {
                    setBorrowProtocolLimitsPaused(WBTC_ETH_DEX, WBTC_ADDRESS);

                    setBorrowProtocolLimitsPaused(WBTC_ETH_DEX, ETH_ADDRESS);
                }
            }

            {
                // Pause user supply and borrow
                address[] memory supplyTokens = new address[](2);
                supplyTokens[0] = WBTC_ADDRESS;
                supplyTokens[1] = ETH_ADDRESS;

                address[] memory borrowTokens = new address[](2);
                borrowTokens[0] = WBTC_ADDRESS;
                borrowTokens[1] = ETH_ADDRESS;

                // Pause the user operations
                LIQUIDITY.pauseUser(WBTC_ETH_DEX, supplyTokens, borrowTokens);
            }
        }
        {
            address cbBTC_ETH_DEX = getDexAddress(7);
            {
                // cbBTC-ETH DEX
                {
                    setSupplyProtocolLimitsPaused(cbBTC_ETH_DEX, cbBTC_ADDRESS);

                    setSupplyProtocolLimitsPaused(cbBTC_ETH_DEX, ETH_ADDRESS);
                }
                {
                    setBorrowProtocolLimitsPaused(cbBTC_ETH_DEX, cbBTC_ADDRESS);

                    setBorrowProtocolLimitsPaused(cbBTC_ETH_DEX, ETH_ADDRESS);
                }
            }

            {
                // Pause user supply and borrow
                address[] memory supplyTokens = new address[](2);
                supplyTokens[0] = cbBTC_ADDRESS;
                supplyTokens[1] = ETH_ADDRESS;

                address[] memory borrowTokens = new address[](2);
                borrowTokens[0] = cbBTC_ADDRESS;
                borrowTokens[1] = ETH_ADDRESS;

                // Pause the user operations
                LIQUIDITY.pauseUser(cbBTC_ETH_DEX, supplyTokens, borrowTokens);
            }
        }
        {
            address USDe_USDC_DEX = getDexAddress(8);
            {
                // cbBTC-ETH DEX
                {
                    setSupplyProtocolLimitsPaused(USDe_USDC_DEX, USDe_ADDRESS);

                    setSupplyProtocolLimitsPaused(USDe_USDC_DEX, USDC_ADDRESS);
                }
                {
                    setBorrowProtocolLimitsPaused(USDe_USDC_DEX, USDe_ADDRESS);

                    setBorrowProtocolLimitsPaused(USDe_USDC_DEX, USDC_ADDRESS);
                }
            }

            {
                // Pause user supply and borrow
                address[] memory supplyTokens = new address[](2);
                supplyTokens[0] = USDe_ADDRESS;
                supplyTokens[1] = USDC_ADDRESS;

                address[] memory borrowTokens = new address[](2);
                borrowTokens[0] = USDe_ADDRESS;
                borrowTokens[1] = USDC_ADDRESS;

                // Pause the user operations
                LIQUIDITY.pauseUser(USDe_USDC_DEX, supplyTokens, borrowTokens);
            }
        }

        {
            address FLUID_ETH_DEX = getDexAddress(10);
            {
                // cbBTC-ETH DEX
                {
                    setSupplyProtocolLimitsPaused(FLUID_ETH_DEX, FLUID_ADDRESS);

                    setSupplyProtocolLimitsPaused(FLUID_ETH_DEX, ETH_ADDRESS);
                }
            }

            {
                // Pause user supply and borrow
                address[] memory supplyTokens = new address[](2);
                supplyTokens[0] = FLUID_ADDRESS;
                supplyTokens[1] = ETH_ADDRESS;

                address[] memory borrowTokens = new address[](0);

                // Pause the user operations
                LIQUIDITY.pauseUser(FLUID_ETH_DEX, supplyTokens, borrowTokens);
            }
        }
    }

    // @notice Action 8: Set Launch Limits for RLP-USDC DEX
    function action8() internal isActionSkippable(8) {
        address RLP_USDC_DEX = getDexAddress(28);
        {
            // RLP-USDC DEX
            DexConfig memory DEX_RLP_USDC = DexConfig({
                dex: RLP_USDC_DEX,
                tokenA: RLP_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 6_500_000, // $6.5M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_RLP_USDC); // Smart Collateral

            DEX_FACTORY.setDexAuth(RLP_USDC_DEX, TEAM_MULTISIG, false);
        }

        {
            address fSL28_RLP_USDC = getSmartLendingAddress(28);

            // set rebalancer at fSL28 to reserve contract proxy
            ISmartLendingAdmin(fSL28_RLP_USDC).setRebalancer(
                address(FLUID_RESERVE)
            );
        }
        {
            IFluidDex(RLP_USDC_DEX).updateMaxSupplyShares(
                5_000_000 * 1e18 // $5M
            );
        }
    }

    // @notice Action 9: Set Launch Limits for Gold Vaults and DEX
    function action9() internal isActionSkippable(9) {
        {
            // PAXG-XAUT DEX
            address PAXG_XAUT_DEX = getDexAddress(32);
            {
                DexConfig memory DEX_PAXG_XAUT = DexConfig({
                    dex: PAXG_XAUT_DEX,
                    tokenA: PAXG_ADDRESS,
                    tokenB: XAUT_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 1_000_000, // $1M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_PAXG_XAUT); // Smart Collateral

                DEX_FACTORY.setDexAuth(PAXG_XAUT_DEX, TEAM_MULTISIG, false);
            }
            {
                IFluidDex(PAXG_XAUT_DEX).updateMaxSupplyShares(
                    1_800_000 * 1e18 // $1.8M
                );
            }
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
                    baseWithdrawalLimitInUSD: 750_000, // $750k
                    baseBorrowLimitInUSD: 750_000, // $750k
                    maxBorrowLimitInUSD: 1_400_000 // $1.4M
                });

                setVaultLimits(VAULT_XAUT_USDC); // TYPE_1 => 116

                VAULT_FACTORY.setVaultAuth(
                    XAUT_USDC_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseWithdrawalLimitInUSD: 750_000, // $750k
                    baseBorrowLimitInUSD: 750_000, // $750k
                    maxBorrowLimitInUSD: 1_400_000 // $1.4M
                });

                setVaultLimits(VAULT_XAUT_USDT); // TYPE_1 => 117

                VAULT_FACTORY.setVaultAuth(
                    XAUT_USDT_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseWithdrawalLimitInUSD: 750_000, // $750k
                    baseBorrowLimitInUSD: 750_000, // $750k
                    maxBorrowLimitInUSD: 1_400_000 // $1.4M
                });

                setVaultLimits(VAULT_XAUT_GHO); // TYPE_1 => 118

                VAULT_FACTORY.setVaultAuth(
                    XAUT_GHO_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseWithdrawalLimitInUSD: 1_000_000, // $1M
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_500_000 // $2.5M
                });

                setVaultLimits(VAULT_PAXG_USDC); // TYPE_1 => 119

                VAULT_FACTORY.setVaultAuth(
                    PAXG_USDC_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseWithdrawalLimitInUSD: 1_000_000, // $1M
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_500_000 // $2.5M
                });

                setVaultLimits(VAULT_PAXG_USDT); // TYPE_1 => 120

                VAULT_FACTORY.setVaultAuth(
                    PAXG_USDT_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseWithdrawalLimitInUSD: 1_000_000, // $1M
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_500_000 // $2.5M
                });

                setVaultLimits(VAULT_PAXG_GHO); // TYPE_1 => 121

                VAULT_FACTORY.setVaultAuth(
                    PAXG_GHO_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_000_000 // $2M
                });

                setVaultLimits(VAULT_PAXG_XAUT__USDC); // TYPE_2 => 122

                VAULT_FACTORY.setVaultAuth(
                    PAXG_XAUT__USDC_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_000_000 // $2M
                });

                setVaultLimits(VAULT_PAXG_XAUT__USDT); // TYPE_2 => 123

                VAULT_FACTORY.setVaultAuth(
                    PAXG_XAUT__USDT_VAULT,
                    TEAM_MULTISIG,
                    false
                );
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
                    baseBorrowLimitInUSD: 1_000_000, // $1M
                    maxBorrowLimitInUSD: 2_000_000 // $2M
                });

                setVaultLimits(VAULT_PAXG_XAUT__GHO); // TYPE_2 => 124

                VAULT_FACTORY.setVaultAuth(
                    PAXG_XAUT__GHO_VAULT,
                    TEAM_MULTISIG,
                    false
                );
            }
        }
    }

    // @notice Action 10: Update Borrow Limits for sUSDe/USDC
    function action10() internal isActionSkippable(10) {
        address sUSDe_USDC_VAULT = getVaultAddress(7);
        {
            // Set supply protocol limits
            SupplyProtocolConfig memory supplyConfig_ = SupplyProtocolConfig({
                protocol: sUSDe_USDC_VAULT,
                supplyToken: sUSDe_ADDRESS,
                expandPercent: 1 * 1e2, // 1%
                expandDuration: 720 hours, // 720 hours
                baseWithdrawalLimitInUSD: 0 // $0
            });
            setSupplyProtocolLimits(supplyConfig_);

            // Set borrow protocol limits
            BorrowProtocolConfig memory borrowConfig_ = BorrowProtocolConfig({
                protocol: sUSDe_USDC_VAULT,
                borrowToken: USDC_ADDRESS,
                expandPercent: 1 * 1e2, // 1%
                expandDuration: 720 hours, // 720 hours
                baseBorrowLimitInUSD: 2_500, // $2.5k
                maxBorrowLimitInUSD: 2_500 // $2.5k
            });
            setBorrowProtocolLimits(borrowConfig_);
        }
    }

    /**
     * |
     * |     Payload Actions End Here      |
     * |__________________________________
     */

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 1_750 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 2_300 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 1_975 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 1_930 * 1e2;
    uint256 public constant mETH_USD_PRICE = 2_000 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 1_975 * 1e2;

    uint256 public constant BTC_USD_PRICE = 94_500 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 5 * 1e2;

    uint256 public constant RLP_USD_PRICE = 1.16 * 1e2;
    uint256 public constant wstUSR_USD_PRICE = 1.07 * 1e2;

    uint256 public constant XAUT_USD_PRICE = 3_400 * 1e2;
    uint256 public constant PAXG_USD_PRICE = 3_400 * 1e2;

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
