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

contract PayloadIGP100 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 100;

    function execute() public virtual override {
        super.execute();

        // Action 1: Adjust all fTokens to 50% expand percentage
        action1();

        // Action 2: Adjust USDTb rate curve
        action2();

        // Action 3: Set Launch Limits for USDTb vaults
        action3();

        // Action 4: Set Dust Limits for USDTb smart vaults
        action4();

        // Action 5: Reduce Borrow Expand Percentage on (s)USDe-USDT T4 vaults back to 30%
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

    // @notice Action 1: Adjust all fTokens to 50% expand percentage
    function action1() internal isActionSkippable(1) {
        setFTokenExpandPercentage(F_WETH_ADDRESS, ETH_ADDRESS);
        setFTokenExpandPercentage(F_WSTETH_ADDRESS, wstETH_ADDRESS);
        setFTokenExpandPercentage(F_USDT_ADDRESS, USDT_ADDRESS);
        setFTokenExpandPercentage(F_USDC_ADDRESS, USDC_ADDRESS);
        setFTokenExpandPercentage(F_GHO_ADDRESS, GHO_ADDRESS);
        setFTokenExpandPercentage(F_SUSDs_ADDRESS, sUSDe_ADDRESS);
    }

    // @notice Action 2: Adjust USDTb rate curve
    function action2() internal isActionSkippable(2) {
        {
            FluidLiquidityAdminStructs.RateDataV2Params[]
                memory params_ = new FluidLiquidityAdminStructs.RateDataV2Params[](
                    1
                );

            params_[0] = FluidLiquidityAdminStructs.RateDataV2Params({
                token: USDTb_ADDRESS, // USDTb
                kink1: 85 * 1e2, // 85%
                kink2: 93 * 1e2, // 93%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 6 * 1e2, // 6%
                rateAtUtilizationKink2: 8 * 1e2, // 8%
                rateAtUtilizationMax: 40 * 1e2 // 40%
            });

            LIQUIDITY.updateRateDataV2s(params_);
        }
    }

    // @notice Action 3: Set Launch Limits for USDTb vaults
    function action3() internal isActionSkippable(3) {
        {
            address ETH_USDTb_VAULT = getVaultAddress(128);

            // [TYPE 1] ETH/USDTb vault
            VaultConfig memory VAULT_ETH_USDTb = VaultConfig({
                vault: ETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: ETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000_000, // $7M
                baseBorrowLimitInUSD: 7_000_000, // $7M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_ETH_USDTb); // TYPE_1 => 128
            VAULT_FACTORY.setVaultAuth(ETH_USDTb_VAULT, TEAM_MULTISIG, false);
        }

        {
            address WSTETH_USDTb_VAULT = getVaultAddress(129);

            // [TYPE 1] WSTETH/USDTb vault
            VaultConfig memory VAULT_WSTETH_USDTb = VaultConfig({
                vault: WSTETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wstETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000_000, // $7M
                baseBorrowLimitInUSD: 7_000_000, // $7M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_WSTETH_USDTb); // TYPE_1 => 129
            VAULT_FACTORY.setVaultAuth(
                WSTETH_USDTb_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        {
            address WEETH_USDTb_VAULT = getVaultAddress(130);

            // [TYPE 1] WEETH/USDTb vault
            VaultConfig memory VAULT_WEETH_USDTb = VaultConfig({
                vault: WEETH_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: weETH_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000_000, // $7M
                baseBorrowLimitInUSD: 7_000_000, // $7M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_WEETH_USDTb); // TYPE_1 => 130
            VAULT_FACTORY.setVaultAuth(WEETH_USDTb_VAULT, TEAM_MULTISIG, false);
        }

        {
            address WBTC_USDTb_VAULT = getVaultAddress(131);

            // [TYPE 1] WBTC/USDTb vault
            VaultConfig memory VAULT_WBTC_USDTb = VaultConfig({
                vault: WBTC_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: WBTC_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000_000, // $7M
                baseBorrowLimitInUSD: 7_000_000, // $7M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_WBTC_USDTb); // TYPE_1 => 131
            VAULT_FACTORY.setVaultAuth(WBTC_USDTb_VAULT, TEAM_MULTISIG, false);
        }

        {
            address CBBTC_USDTb_VAULT = getVaultAddress(132);

            // [TYPE 1] CBBTC/USDTb vault
            VaultConfig memory VAULT_CBBTC_USDTb = VaultConfig({
                vault: CBBTC_USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: cbBTC_ADDRESS,
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 7_000_000, // $7M
                baseBorrowLimitInUSD: 7_000_000, // $7M
                maxBorrowLimitInUSD: 10_000_000 // $10M
            });

            setVaultLimits(VAULT_CBBTC_USDTb); // TYPE_1 => 132
            VAULT_FACTORY.setVaultAuth(CBBTC_USDTb_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 4: Set Dust Limits for USDTb smart vaults
    function action4() internal isActionSkippable(4) {
        {
            address USDE_USDTb__USDTb_VAULT = getVaultAddress(136);

            // [TYPE 2] USDE-USDTb<>USDTb | smart collateral & debt
            VaultConfig memory VAULT_USDE_USDTb_USDTb = VaultConfig({
                vault: USDE_USDTb__USDTb_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDTb_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDE_USDTb_USDTb);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDTb_VAULT,
                TEAM_MULTISIG,
                true
            );
        }

        {
            address USDE_USDTb__USDT_VAULT = getVaultAddress(137);

            // USDE-USDTb / USDT T2 vault
            Vault memory VAULT_USDE_USDTb_USDT = Vault({
                vault: USDE_USDTb__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0), // supply token (DEX LP)
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDE_USDTb_USDT);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDT_VAULT,
                TEAM_MULTISIG,
                true
            );
        }

        {
            address USDE_USDTb__USDC_VAULT = getVaultAddress(138);

            // USDE-USDTb / USDC T2 vault
            Vault memory VAULT_USDE_USDTb_USDC = Vault({
                vault: USDE_USDTb__USDC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0), // supply token (DEX LP)
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_000, // $7k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_USDE_USDTb_USDC);

            VAULT_FACTORY.setVaultAuth(
                USDE_USDTb__USDC_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 5: Reduce Borrow Expand Percentage on (s)USDe-USDT T4 vaults back to 30%
    function action5() internal isActionSkippable(5) {
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
                    expandPercent: 30 * 1e2, // 30%
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
                    expandPercent: 30 * 1e2, // 30%
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

    // @notice Action 6: Increase Caps on GHO-sUSDe
    function action6() internal isActionSkippable(6) {
        address GHO_sUSDe_DEX = getDexAddress(33);

        {
            // Set max sypply shares
            IFluidDex(GHO_sUSDe_DEX).updateMaxSupplyShares(
                10_000_000 * 1e18 // from 10M shares
            );
        }
    }

    // @notice Action 7: Set dust limits for wstUSR-USDC DEX and its vaults
    function action7() internal isActionSkippable(7) {
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
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_wstUSR_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(wstUSR_USDC_DEX, TEAM_MULTISIG, true);
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
                    baseBorrowLimitInUSD: 7_000, // $7k
                    maxBorrowLimitInUSD: 10_000 // $10k
                });

                setVaultLimits(VAULT_wstUSR_USDC_USDC); // TYPE_2 => 136
                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_VAULT,
                    TEAM_MULTISIG,
                    true
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
                        baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                        maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                    });

                    IFluidDex(USDC_USDT_DEX).updateUserBorrowConfigs(config_);
                }

                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_USDT_VAULT,
                    TEAM_MULTISIG,
                    true
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
                        user: wstUSR_USDC__USDC_USDT_VAULT,
                        expandPercent: 30 * 1e2, // 20%
                        expandDuration: 6 hours, // 12 hours
                        baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                        maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                    });

                    IFluidDex(USDC_USDT_CONCENTRATED_DEX)
                        .updateUserBorrowConfigs(config_);
                }

                VAULT_FACTORY.setVaultAuth(
                    wstUSR_USDC__USDC_USDT_CONCENTRATED_VAULT,
                    TEAM_MULTISIG,
                    true
                );
            }
        }
    }

    // @notice Action 8: Set dust limits for GHO-USDe DEX
    function action8() internal isActionSkippable(8) {
        {
            // GHO-USDe DEX
            DexConfig memory DEX_GHO_USDe = DexConfig({
                dex: GHO_USDe_DEX,
                tokenA: GHO_ADDRESS,
                tokenB: USDe_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_GHO_USDe); // Smart Collateral

            DEX_FACTORY.setDexAuth(GHO_USDe_DEX, TEAM_MULTISIG, true);
        }

        {
            address GHO_USDe__GHO_USDC_VAULT = getVaultAddress(136);
            address GHO_USDC_DEX = getDexAddress(4);

            {
                // Update GHO-USDe<>GHO-USDC vault borrow shares limit
                IFluidAdminDex.UserBorrowConfig[]
                    memory config_ = new IFluidAdminDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: GHO_USDe__GHO_USDC_VAULT,
                    expandPercent: 30 * 1e2, // 20%
                    expandDuration: 6 hours, // 12 hours
                    baseDebtCeiling: 4_000 * 1e18, // 4k shares ($8k)
                    maxDebtCeiling: 5_000 * 1e18 // 5k shares ($10k)
                });

                IFluidDex(GHO_USDC_DEX).updateUserBorrowConfigs(config_);
            }

            VAULT_FACTORY.setVaultAuth(
                GHO_USDe__GHO_USDC_VAULT,
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

    /**
     * @notice Helper function to set expand percentage for fTokens
     * @param fTokenAddress The address of the fToken
     * @param underlyingToken The address of the underlying token
     */
    function setFTokenExpandPercentage(
        address fTokenAddress,
        address underlyingToken
    ) internal {
        IFTokenAdmin fToken = IFTokenAdmin(address(fTokenAddress));

        SupplyProtocolConfig
            memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: address(fToken),
                supplyToken: underlyingToken,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: 10_000_000 // $10M
            });

        setSupplyProtocolLimits(protocolConfigTokenB_);
    }

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
