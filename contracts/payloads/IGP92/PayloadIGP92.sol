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

contract PayloadIGP92 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 92;

    function execute() public virtual override {
        super.execute();

        // Action 1: Set launch allowance for sUSDS<>USDT DEX
        action1();

        // Action 2: Update Multisig Authorization for sUSDS<>USDT T4 vault
        action2();

        // Action 3: Set launch limits of LBTC-stable vaults
        action3();

        // Action 4: Set Rebalancer for sUSDS-USDT
        action4();

        // Action 5: Update supply and borrow shares for LBTC-cbBTC DEX
        action5();

        // Action 6: Update GHO-USDC Caps and parameters
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


    // @notice Action 1: Set launch allowance for sUSDS<>USDT DEX
    function action1() internal isActionSkippable(1) {
        address SUSDS_USDT_DEX_ADDRESS = getDexAddress(31);

        {  // Set SUSDS-USDT Dex Pool Limits
            DexConfig memory DEX_SUSDS_USDT = DexConfig({
                dex: SUSDS_USDT_DEX_ADDRESS,
                tokenA: sUSDs_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 11_250_000, // $11.25M
                baseBorrowLimitInUSD: 12_000_000, // $12M
                maxBorrowLimitInUSD: 25_000_000 // $25M
            });
            setDexLimits(DEX_SUSDS_USDT); // Smart Collateral & Smart Debt

            { // remove multisig as DEX auth
                DEX_FACTORY.setDexAuth(SUSDS_USDT_DEX_ADDRESS, TEAM_MULTISIG, false);
            }
        }
    }

    // @notice Action 2: Update Multisig Authorization for sUSDS<>USDT T4 vault
    function action2() internal isActionSkippable(2) {
        address SUSDS_USDT_VAULT_ADDRESS = getVaultAddress(116);

        { // remove multisig as T4 vault auth
            VAULT_FACTORY.setVaultAuth(
                SUSDS_USDT_VAULT_ADDRESS,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Set launch limits of LBTC-stable vaults
    function action3() internal isActionSkippable(3){
        {
            address LBTC_USDC_VAULT = getVaultAddress(107);

            // [TYPE 1] LBTC/USDC vault
            VaultConfig memory VAULT_LBTC_USDC = VaultConfig({
                vault: LBTC_USDC_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_LBTC_USDC); // TYPE_1 => 107

            VAULT_FACTORY.setVaultAuth(LBTC_USDC_VAULT, TEAM_MULTISIG, false);
        }

        {
            address LBTC_USDT_VAULT = getVaultAddress(108);

            // [TYPE 1] LBTC/USDT vault
            VaultConfig memory VAULT_LBTC_USDT = VaultConfig({
                vault: LBTC_USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_LBTC_USDT); // TYPE_1 => 108

            VAULT_FACTORY.setVaultAuth(LBTC_USDT_VAULT, TEAM_MULTISIG, false);
        }

        {
            address LBTC_GHO_VAULT = getVaultAddress(109);

            // [TYPE 1] LBTC/GHO vault
            VaultConfig memory VAULT_LBTC_GHO = VaultConfig({
                vault: LBTC_GHO_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_LBTC_GHO); // TYPE_1 => 109

            VAULT_FACTORY.setVaultAuth(LBTC_GHO_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 4: Set Rebalancer for sUSDS-USDT
    function action4() internal isActionSkippable(4) {
        {
            address fSL31_SUSDS_USDT = getSmartLendingAddress(31);

            // set rebalancer at fSL31 to reserve contract proxy
            ISmartLendingAdmin(fSL31_SUSDS_USDT).setRebalancer(
                address(FLUID_RESERVE)
            );
        }
    }

    // @notice Action 5: Update supply shares for LBTC-cbBTC DEX and borrow limits for LBTC-cbBTC | cbBTC
    function action5() internal isActionSkippable(5) {
        address LBTC_cbBTC_DEX = getDexAddress(17);

        // Update max supply shares on dex
        IFluidDex(LBTC_cbBTC_DEX).updateMaxSupplyShares(
            200 * 1e18 // 200 shares = 33M
        );

        address LBTC_cbBTC__cbBTC_VAULT = getVaultAddress(114);

        {
            // [TYPE 2] LBTC-cbBTC<>cbBTC vault
            VaultConfig memory VAULT_LBTC_cbBTC__cbBTC = VaultConfig({
                vault: LBTC_cbBTC__cbBTC_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at dex
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 25_000_000 // $25M
            });
            setVaultLimits(VAULT_LBTC_cbBTC__cbBTC);
        }

    }

    // @notice Action 6: Update GHO-USDC Caps and parameters
    function action6() internal isActionSkippable(6) {
        address GHO_USDC_VAULT_ADDRESS = getVaultAddress(61);
        address GHO_USDC_DEX_ADDRESS = getDexAddress(4);

        {  // Increase GHO-USDC Dex Pool Limits
            DexConfig memory DEX_GHO_USDC = DexConfig({
                dex: GHO_USDC_DEX_ADDRESS,
                tokenA: GHO_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 11_250_000, // $7.5M
                baseBorrowLimitInUSD: 9_000_000, // $9M
                maxBorrowLimitInUSD: 12_750_000 // $12.75M
            });
            setDexLimits(DEX_GHO_USDC); // Smart Collateral & Smart Debt
        }

        { // Increase GHO-USDC Max Shares
            IFluidDex(GHO_USDC_DEX_ADDRESS).updateMaxSupplyShares(
                7_500_000 * 1e18 // 7.5M shares
            );

            IFluidDex(GHO_USDC_DEX_ADDRESS).updateMaxBorrowShares(
                6_000_000 * 1e18 // 6M shares
            );
        }


        { // Increase [TYPE 4] GHO-USDC | GHO-USDC | Smart collateral & smart debt
            {
                IFluidDex.UserSupplyConfig[]
                    memory config_ = new IFluidDex.UserSupplyConfig[](1);
                config_[0] = IFluidAdminDex.UserSupplyConfig({
                    user: GHO_USDC_VAULT_ADDRESS,
                    expandPercent: 35 * 1e2, // 35%
                    expandDuration: 6 hours, // 6 hours
                    baseWithdrawalLimit: 4_500_000 * 1e18 // 4.5M shares
                });

                IFluidDex(GHO_USDC_DEX_ADDRESS).updateUserSupplyConfigs(
                    config_
                );
            }

            {
                IFluidDex.UserBorrowConfig[]
                    memory config_ = new IFluidDex.UserBorrowConfig[](1);
                config_[0] = IFluidAdminDex.UserBorrowConfig({
                    user: GHO_USDC_VAULT_ADDRESS,
                    expandPercent: 30 * 1e2, // 30%
                    expandDuration: 6 hours, // 6 hours
                    baseDebtCeiling: 4_500_000 * 1e18, // 4.5M shares
                    maxDebtCeiling: 6_000_000 * 1e18 // 6M shares
                });

                IFluidDex(GHO_USDC_DEX_ADDRESS).updateUserBorrowConfigs(
                    config_
                );
            }
        }

        uint256 CF = 92 * 1e2;
        uint256 LT = 95 * 1e2;
        uint256 LML = 96 * 1e2;

        IFluidVaultT1(GHO_USDC_VAULT_ADDRESS).updateLiquidationMaxLimit(LML);
        IFluidVaultT1(GHO_USDC_VAULT_ADDRESS).updateLiquidationThreshold(LT);
        IFluidVaultT1(GHO_USDC_VAULT_ADDRESS).updateCollateralFactor(CF);
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
