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

contract PayloadIGP87 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 87;

    function execute() public virtual override {
        super.execute();

        // Action 1: Increase Borrow Cap for wstETH/ETH vault
        action1();

        // Action 2: Set dust limits for LBTC<>stable vaults
        action2();

        // Action 3: Set dust limits for RLP/USDC vault
        action3();

        // Action 4: Set dust limits for wstUSR vaults and DEX
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

    // @notice Action 1: Increase Borrow Cap for wstETH/ETH vault
    function action1() internal isActionSkippable(1) {
        address wstETH_ETH_VAULT = getVaultAddress(13);

        // [TYPE 1] wstETH/ETH vault
        VaultConfig memory VAULT_wstETH_ETH = VaultConfig({
            vault: wstETH_ETH_VAULT,
            vaultType: VAULT_TYPE.TYPE_1,
            supplyToken: wstETH_ADDRESS,
            borrowToken: ETH_ADDRESS,
            baseWithdrawalLimitInUSD: 15_000_000, // $15M
            baseBorrowLimitInUSD: 15_000_000, // $15M
            maxBorrowLimitInUSD: 175_000_000 // $175M
        });

        setVaultLimits(VAULT_wstETH_ETH); // TYPE_1 => 13
    }

    // @notice Action 2: Set dust limits for LBTC<>stable vaults
    function action2() internal isActionSkippable(2) {
        {
            address LBTC_USDC_VAULT = getVaultAddress(107);

            // [TYPE 1] LBTC/USDC vault
            VaultConfig memory VAULT_LBTC_USDC = VaultConfig({
                vault: LBTC_USDC_VAULT,
                vaultType: VAULT_TYPE.TYPE_1,
                supplyToken: LBTC_ADDRESS,
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
                supplyToken: LBTC_ADDRESS,
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
                supplyToken: LBTC_ADDRESS,
                borrowToken: GHO_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_LBTC_GHO); // TYPE_1 => 109

            VAULT_FACTORY.setVaultAuth(LBTC_GHO_VAULT, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 3: Set dust limits for RLP/USDC vault
    function action3() internal isActionSkippable(3) {
        address RLP_USDC_VAULT = getVaultAddress(110);

        // [TYPE 1] RLP/USDC vault
        VaultConfig memory VAULT_RLP_USDC = VaultConfig({
            vault: RLP_USDC_VAULT,
            vaultType: VAULT_TYPE.TYPE_1,
            supplyToken: RLP_ADDRESS,
            borrowToken: USDC_ADDRESS,
            baseWithdrawalLimitInUSD: 10_000, // $10k
            baseBorrowLimitInUSD: 10_000, // $10k
            maxBorrowLimitInUSD: 15_000 // $15k
        });

        setVaultLimits(VAULT_RLP_USDC); // TYPE_1 => 110

        VAULT_FACTORY.setVaultAuth(RLP_USDC_VAULT, TEAM_MULTISIG, true);
    }

    // @notice Action 4: Set dust limits for wstUSR vaults and DEX
    function action4() internal isActionSkippable(4) {
        {
            address wstUSR_USDC_DEX = getDexAddress(27);

            // wstUSR-USDC DEX
            DexConfig memory DEX_wstUSR_USDC = DexConfig({
                dex: wstUSR_USDC_DEX,
                tokenA: wstUSR_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });
            setDexLimits(DEX_wstUSR_USDC); // Smart Collateral & Smart Debt

            DEX_FACTORY.setDexAuth(wstUSR_USDC_DEX, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDC_VAULT = getVaultAddress(111);

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

            setVaultLimits(VAULT_wstUSR_USDC); // TYPE_1 => 111

            VAULT_FACTORY.setVaultAuth(wstUSR_USDC_VAULT, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDT_VAULT = getVaultAddress(112);

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

            setVaultLimits(VAULT_wstUSR_USDT); // TYPE_1 => 112

            VAULT_FACTORY.setVaultAuth(wstUSR_USDT_VAULT, TEAM_MULTISIG, true);
        }

        {
            address wstUSR_USDC__USDT_VAULT = getVaultAddress(113);

            // [TYPE 2] wstUSR-USDC<>USDT vault
            VaultConfig memory VAULT_wstUSR_USDC_USDT = VaultConfig({
                vault: wstUSR_USDC__USDT_VAULT,
                vaultType: VAULT_TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at DEX
                baseBorrowLimitInUSD: 10_000, // $10k
                maxBorrowLimitInUSD: 15_000 // $15k
            });

            setVaultLimits(VAULT_wstUSR_USDC_USDT); // TYPE_2 => 113

            VAULT_FACTORY.setVaultAuth(wstUSR_USDC__USDT_VAULT, TEAM_MULTISIG, true);
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
