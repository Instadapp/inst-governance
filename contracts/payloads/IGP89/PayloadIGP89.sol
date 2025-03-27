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

contract PayloadIGP89 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 89;

    function execute() public virtual override {
        super.execute();

        // Action 1: Set dust limits for LBTC<>stable vaults
        action1();

        // Action 2: Set dust limits for RLP-USDC DEX
        action2();

        // Action 3: Set dust limits for wstUSR DEXes and vaults
        action3();

        // Action 4: Update supply shares for cbBTC-wBTC Dex pool
        action4();

        // Action 5: Update USDC-USDT Dex Fee Handler
        action5();

        // Action 6: Set dust limits for WBTC<>LBTC DEX and vault
        action6();

        // Action 7: Update Min Max center price of cbBTC-WBTC DEX
        action7();

        // Action 8: Set dust limits for LBTC-cbBTC DEX and vaults
        action8();
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

    // @notice Action 1: Set dust limits for LBTC<>stable vaults
    function action1() internal isActionSkippable(1) {
        {
            address LBTC_USDC_VAULT = getVaultAddress(107);

            // [TYPE 1] LBTC/USDC vault
            VaultConfig memory VAULT_LBTC_USDC = VaultConfig({
                vault: LBTC_USDC_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_LBTC_USDC); // TYPE_1 => 107

            VAULT_FACTORY.setVaultAuth(LBTC_USDC_VAULT, TEAM_MULTISIG, true);
        }

        {
            address LBTC_USDT_VAULT = getVaultAddress(108);

            // [TYPE 1] LBTC/USDT vault
            VaultConfig memory VAULT_LBTC_USDT = VaultConfig({
                vault: LBTC_USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_LBTC_USDT); // TYPE_1 => 108

            VAULT_FACTORY.setVaultAuth(LBTC_USDT_VAULT, TEAM_MULTISIG, true);
        }

        {
            address LBTC_GHO_VAULT = getVaultAddress(109);

            // [TYPE 1] LBTC/GHO vault
            VaultConfig memory VAULT_LBTC_GHO = VaultConfig({
                vault: LBTC_GHO_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: lBTC_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_LBTC_GHO); // TYPE_1 => 109

            VAULT_FACTORY.setVaultAuth(LBTC_GHO_VAULT, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 2: Set dust limits for RLP-USDC DEX
    function action2() internal isActionSkippable(2) {
        address RLP_USDC_DEX = getDexAddress(28);

        // RLP-USDC DEX
        DexConfig memory DEX_RLP_USDC = DexConfig({
            dex: RLP_USDC_DEX,
            tokenA: RLP_ADDRESS,
            tokenB: USDC_ADDRESS,
            smartCollateral: true,
            smartDebt: false,
            baseWithdrawalLimitInUSD: 10_000, // $10k
            baseBorrowLimitInUSD: 0, // $0
            maxBorrowLimitInUSD: 0 // $0
        });
        setDexLimits(DEX_RLP_USDC); // Smart Collateral

        DEX_FACTORY.setDexAuth(RLP_USDC_DEX, TEAM_MULTISIG, true);
    }

    // @notice Action 3: Set dust limits for wstUSR DEXes and vaults
    function action3() internal isActionSkippable(3) {

        {
            address wstUSR_USDC_VAULT = getVaultAddress(110);

            // [TYPE 1] wstUSR/USDC vault
            VaultConfig memory VAULT_wstUSR_USDC = VaultConfig({
                vault: wstUSR_USDC_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wstUSR_ADDRESS,
                borrowToken: USDC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_wstUSR_USDC); // TYPE_1 => 110

            VAULT_FACTORY.setVaultAuth(wstUSR_USDC_VAULT, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDT_VAULT = getVaultAddress(111);

            // [TYPE 1] wstUSR/USDT vault
            VaultConfig memory VAULT_wstUSR_USDT = VaultConfig({
                vault: wstUSR_USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wstUSR_ADDRESS,
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_wstUSR_USDT); // TYPE_1 => 111

            VAULT_FACTORY.setVaultAuth(wstUSR_USDT_VAULT, TEAM_MULTISIG, true);
        }


        {
            address wstUSR_GHO_VAULT = getVaultAddress(112);

            // [TYPE 1] wstUSR/GHO vault
            VaultConfig memory VAULT_wstUSR_GHO = VaultConfig({
                vault: wstUSR_GHO_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: wstUSR_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_wstUSR_GHO); // TYPE_1 => 112

            VAULT_FACTORY.setVaultAuth(wstUSR_GHO_VAULT, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDT_DEX = getDexAddress(29);

            // wstUSR-USDT DEX
            DexConfig memory DEX_wstUSR_USDT = DexConfig({
                dex: wstUSR_USDT_DEX,
                tokenA: wstUSR_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_wstUSR_USDT); // Smart Collateral
            DEX_FACTORY.setDexAuth(wstUSR_USDT_DEX, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDT__USDT_VAULT = getVaultAddress(113);

            // [TYPE 2] wstUSR-USDT<>USDT vault
            VaultConfig memory VAULT_wstUSR_USDT_USDT = VaultConfig({
                vault: wstUSR_USDT__USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at DEX
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_wstUSR_USDT_USDT); // TYPE_2 => 113

            VAULT_FACTORY.setVaultAuth(wstUSR_USDT__USDT_VAULT, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 4: Update supply shares for cbBTC-wBTC Dex pool
    function action4() internal isActionSkippable(4) {
        address CBBTC_WBTC_DEX_ADDRESS = getDexAddress(3);

        // Update max supply shares on dex
        IFluidDex(CBBTC_WBTC_DEX_ADDRESS).updateMaxSupplyShares(
            250 * 1e18 // 250 shares
        );
    }

    // @notice Action 5: Update USDC-USDT Dex auth
    function action5() internal isActionSkippable(5) {
        address USDC_USDT_DEX = getDexAddress(2);

        // Fee Handler Addresses
        address oldFeeHandler = 0x30F509D6B5c33c15909D4B7257202c79b4dC1183;
        address newFeeHandler = 0x65454D16A39c7b5b52A67116FC1cf0a5e5942EFd;

        // Remove old handler as auth
        DEX_FACTORY.setDexAuth(USDC_USDT_DEX, oldFeeHandler, false);

        // Add new handler as auth
        DEX_FACTORY.setDexAuth(USDC_USDT_DEX, newFeeHandler, true);
    }

    // @notice Action 6: Set dust limits for WBTC<>LBTC DEX and vault
    function action6() internal isActionSkippable(6) {
        address WBTC_LBTC_DEX = getDexAddress(30);
        address WBTC_LBTC__WBTC_VAULT = getVaultAddress(115);

        {
            // WBTC-LBTC Dex
            DexConfig memory DEX_WBTC_LBTC = DexConfig({
                dex: WBTC_LBTC_DEX,
                tokenA: WBTC_ADDRESS,
                tokenB: lBTC_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000, // $10K
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_WBTC_LBTC); // Smart Collateral

            DEX_FACTORY.setDexAuth(WBTC_LBTC_DEX, TEAM_MULTISIG, true);
        }

        {
            // [TYPE 2] WBTC-LBTC<>WBTC vault
            VaultConfig memory VAULT_WBTC_LBTC__WBTC = VaultConfig({
                vault: WBTC_LBTC__WBTC_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 10_000, // $10K
                maxBorrowLimitInUSD: 15_000 // $15K
            });
            setVaultLimits(VAULT_WBTC_LBTC__WBTC);

            VAULT_FACTORY.setVaultAuth(WBTC_LBTC__WBTC_VAULT, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 7: Update Min Max center price of cbBTC-WBTC DEX
    function action7() internal isActionSkippable(7) {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);
        {
        // Update Min Max center prices from 0.2% to 0.15%
            uint256 minCenterPrice_ = (998 * 1e27) / 1000;
            uint256 maxCenterPrice_ = uint256(1e27 * 1000) / 998.5;
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
                maxCenterPrice_,
                minCenterPrice_
            );
        }
    }

    // @notice Action 8: Set dust limits for LBTC-cbBTC<>cbBTC vaults
    function action8() internal isActionSkippable(8) {
        address LBTC_cbBTC_DEX = getDexAddress(17);
        address LBTC_cbBTC__cbBTC_VAULT = getVaultAddress(114);

        {
            // [TYPE 2] LBTC-cbBTC<>cbBTC vault
            VaultConfig memory VAULT_LBTC_cbBTC__cbBTC = VaultConfig({
                vault: LBTC_cbBTC__cbBTC_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at dex
                baseBorrowLimitInUSD: 10_000, // $10K
                maxBorrowLimitInUSD: 15_000 // $15K
            });
            setVaultLimits(VAULT_LBTC_cbBTC__cbBTC);

            VAULT_FACTORY.setVaultAuth(LBTC_cbBTC__cbBTC_VAULT, TEAM_MULTISIG, true);
        }

        {
            // Update LBTC-cbBTC<>cbBTC vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: LBTC_cbBTC__cbBTC_VAULT,
                expandPercent: 35 * 1e2, // 35%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimit: 0.05 * 1e8 // 0.05 shares
            });

            IFluidDex(LBTC_cbBTC_DEX).updateUserSupplyConfigs(config_);
        }

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

    uint256 public constant BTC_USD_PRICE = 83_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 5 * 1e2;

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
        } else if (token == wstUSR_ADDRESS) {
            usdPrice = wstUSR_USD_PRICE;
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
