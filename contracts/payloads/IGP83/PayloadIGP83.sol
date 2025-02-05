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

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";
import {PayloadIGPMain} from "../common/main.sol";

contract PayloadIGP83 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 83;

    function execute() public virtual override {
        super.execute();

        // Action 1: Readjust sUSDe-USDT<>USDT witdhrawal limit
        action1();

        // Action 2: Raise fUSDC and fUSDT Rewards Allowance
        action2();

        // Action 3: Set launch limits for USDC collateral vaults
        action3();

        // Action 4: Set launch limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
        action4();

        // Action 5: Update cbBTC-WBTC DEX configs
        action5();

        // Action 6: Update wstETH-ETH, weETH-ETH, rsETH-ETH DEX configs
        action6();

        // Action 7: Update USDC-USDT DEX limits
        action7();

        // Action 8: Set dust limits for USD0-USDC, fxUSD-USDC, USDC-BOLD DEX
        action8();

        // Action 9: Discontinue fGHO rewards
        action9();
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

    // @notice Action 1: Readjust sUSDe-USDT<>USDT withdrawal limit
    function action1() internal isActionSkippable(1) {
        address sUSDe_USDT_DEX_ADDRESS = getDexAddress(15);
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);

        {
            // Update sUSDe-USDT<>USDT vault supply shares limit
            IFluidAdminDex.UserSupplyConfig[]
                memory config_ = new IFluidAdminDex.UserSupplyConfig[](1);
            config_[0] = IFluidAdminDex.UserSupplyConfig({
                user: sUSDe_USDT__USDT_VAULT,
                expandPercent: 35 * 1e2, // 35%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimit: 10_000_000 * 1e18 // 10M shares
            });

            IFluidDex(sUSDe_USDT_DEX_ADDRESS).updateUserSupplyConfigs(config_);
        }
    }

    // @notice Action 2: Raise fUSDC and fUSDT Rewards Allowance
    function action2() internal isActionSkippable(2) {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        address fSTABLES_REWARDS_ADDRESS = 0xb75Ec31fd7ad0D823A801be8740B9Fad299ce6d6;

        {
            /// fUSDC
            IFTokenAdmin(F_USDC_ADDRESS).updateRewards(
                fSTABLES_REWARDS_ADDRESS
            );

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDC_ADDRESS
            );

            protocols[0] = F_USDC_ADDRESS;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (1_500_000 * 1e6); // 1.5M
        }

        {
            /// fUSDT
            IFTokenAdmin(F_USDT_ADDRESS).updateRewards(
                fSTABLES_REWARDS_ADDRESS
            );

            uint256 allowance = IERC20(USDT_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDT_ADDRESS
            );

            protocols[1] = F_USDT_ADDRESS;
            tokens[1] = USDT_ADDRESS;
            amounts[1] = allowance + (1_500_000 * 1e6); // 1.5M
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    // @notice Action 3: Set launch limits for USDC collateral vaults
    function action3() internal isActionSkippable(3) {
        {
            address USDC_ETH_VAULT = getVaultAddress(100);

            // [TYPE 1] USDC<>ETH | collateral & debt
            Vault memory VAULT_USDC_ETH = Vault({
                vault: USDC_ETH_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: ETH_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 60_000_000 // $60M
            });

            setVaultLimits(VAULT_USDC_ETH); // TYPE_1 => 100

            VAULT_FACTORY.setVaultAuth(USDC_ETH_VAULT, TEAM_MULTISIG, false);
        }

        {
            address USDC_WBTC_VAULT = getVaultAddress(101);

            // [TYPE 1] USDC<>WBTC | collateral & debt
            Vault memory VAULT_USDC_WBTC = Vault({
                vault: USDC_WBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });

            setVaultLimits(VAULT_USDC_WBTC); // TYPE_1 => 101

            VAULT_FACTORY.setVaultAuth(USDC_WBTC_VAULT, TEAM_MULTISIG, false);
        }

        {
            address USDC_cbBTC_VAULT = getVaultAddress(102);

            // [TYPE 1] USDC<>cbBTC | collateral & debt
            Vault memory VAULT_USDC_cbBTC = Vault({
                vault: USDC_cbBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: USDC_ADDRESS,
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 30_000_000 // $30M
            });

            setVaultLimits(VAULT_USDC_cbBTC); // TYPE_1 => 102

            VAULT_FACTORY.setVaultAuth(USDC_cbBTC_VAULT, TEAM_MULTISIG, false);
        }
    }

    // @notice Action 4: Set launch limits for ezETH-ETH DEX and ezETH<>wstETH T1 & ezETH-ETH<>wstETH T2 vaults
    function action4() internal isActionSkippable(4) {
        {
            address ezETH_ETH_DEX = getDexAddress(21);
            // ezETH-ETH DEX
            {
                // ezETH-ETH Dex
                Dex memory DEX_ezETH_ETH = Dex({
                    dex: ezETH_ETH_DEX,
                    tokenA: ezETH_ADDRESS,
                    tokenB: ETH_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_ezETH_ETH); // Smart Collateral

                DEX_FACTORY.setDexAuth(ezETH_ETH_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            address ezETH__wstETH_VAULT = getVaultAddress(103);

            // [TYPE 1] ezETH<>wstETH | normal collateral & normal debt
            Vault memory VAULT_ezETH_wstETH = Vault({
                vault: ezETH__wstETH_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: ezETH_ADDRESS,
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 20_000_000 // $20M
            });

            setVaultLimits(VAULT_ezETH_wstETH); // TYPE_1 => 103

            VAULT_FACTORY.setVaultAuth(
                ezETH__wstETH_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        {
            address ezETH_ETH__wstETH_VAULT = getVaultAddress(104);

            // [TYPE 2] ezETH-ETH<>wstETH | smart collateral & normal debt
            Vault memory VAULT_ezETH_ETH_wstETH = Vault({
                vault: ezETH_ETH__wstETH_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: wstETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 7_500_000, // $7.5M
                maxBorrowLimitInUSD: 15_000_000 // $15M
            });

            setVaultLimits(VAULT_ezETH_ETH_wstETH); // TYPE_2 => 104

            VAULT_FACTORY.setVaultAuth(
                ezETH_ETH__wstETH_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 5: Update cbBTC-wBTC DEX configs
    function action5() internal isActionSkippable(5) {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        {
            // update the threshold to 20%
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateThresholdPercent(
                20 * 1e4,
                20 * 1e4,
                16 hours,
                1 days
            );
        }

        {
            // update the upper and lower range +-0.25%
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(
                0.25 * 1e4,
                0.25 * 1e4,
                5 days
            );
        }

        {   // Set max supply shares
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateMaxSupplyShares(
                175 * 1e18
            ); // Current 150 * 1e18
        }

        {   // Set max borrow shares
            IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateMaxBorrowShares(
                125 * 1e18
            ); // Current 120 * 1e18
        }
    }

    // @notice Action 6: Update wstETH-ETH, weETH-ETH, rsETH-ETH DEX configs
    function action6() internal isActionSkippable(6) {
        address wstETH_ETH_DEX_ADDRESS = getDexAddress(1);
        address weETH_ETH_DEX_ADDRESS = getDexAddress(9);
        address rsETH_ETH_DEX_ADDRESS = getDexAddress(13);

        // update the upper and lower range for wstETH-ETH DEX
        IFluidDex(wstETH_ETH_DEX_ADDRESS).updateRangePercents(
            0.0001 * 1e4, // +0.0001%
            0.08 * 1e4, // -0.08%
            0
        );

        // update the upper and lower range for weETH-ETH DEX
        IFluidDex(weETH_ETH_DEX_ADDRESS).updateRangePercents(
            0.0001 * 1e4, // +0.0001%
            0.06 * 1e4, // -0.06%
            0
        );

        // update the upper and lower range for rsETH-ETH DEX
        IFluidDex(rsETH_ETH_DEX_ADDRESS).updateRangePercents(
            0.0001 * 1e4, // +0.0001%
            0.1 * 1e4, // -0.1%
            5 days
        );
    }

    // @notice Action 7: Update USDC-USDT DEX limits
    function action7() internal isActionSkippable(7) {
        address USDC_USDT_DEX_ADDRESS = getDexAddress(2);

        {
            Dex memory DEX_USDC_USDT = Dex({
                dex: USDC_USDT_DEX_ADDRESS,
                tokenA: USDC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: false,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 0, // $0
                baseBorrowLimitInUSD: 20_000_000, // $20M
                maxBorrowLimitInUSD: 60_000_000 // $60M
            });
            setDexLimits(DEX_USDC_USDT); // Smart Debt
        }

        {
            // Set max borrow shares
            IFluidDex(USDC_USDT_DEX_ADDRESS).updateMaxBorrowShares(
                25_000_000 * 1e18
            ); // Current 20_000_000 * 1e18
        }
    }

    // @notice Action 8: Set dust limits for USD0-USDC, fxUSD-USDC, USDC-BOLD DEX
    function action8() internal isActionSkippable(8) {
        {
            address USD0_USDC_DEX = getDexAddress(23);
            // USD0-USDC DEX
            {
                // USD0-USDC Dex
                Dex memory DEX_USD0_USDC = Dex({
                    dex: USD0_USDC_DEX,
                    tokenA: USD0_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USD0_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(USD0_USDC_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            address fxUSD_USDC_DEX = getDexAddress(24);
            // fxUSD-USDC DEX
            {
                // fxUSD-USDC Dex
                Dex memory DEX_fxUSD_USDC = Dex({
                    dex: fxUSD_USDC_DEX,
                    tokenA: fxUSD_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_fxUSD_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(fxUSD_USDC_DEX, TEAM_MULTISIG, true);
            }
        }

        {
            address USDC_BOLD_DEX = getDexAddress(25);
            // USDC-BOLD DEX
            {
                // USDC-BOLD Dex
                Dex memory DEX_USDC_BOLD = Dex({
                    dex: USDC_BOLD_DEX,
                    tokenA: USDC_ADDRESS,
                    tokenB: BOLD_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USDC_BOLD); // Smart Collateral

                DEX_FACTORY.setDexAuth(USDC_BOLD_DEX, TEAM_MULTISIG, true);
            }
        }
    }


    // @notice Action 9: Discontinue fGHO rewards
    function action9() internal isActionSkippable(9) {
        address[] memory protocols = new address[](1);
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        {
            IFTokenAdmin(F_GHO_ADDRESS).updateRewards(address(0));

            uint256 allowance = 210_000 * 1e18; // 210K GHO

            protocols[0] = F_GHO_ADDRESS;
            tokens[0] = GHO_ADDRESS;
            amounts[0] = allowance;
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */
    struct Dex {
        address dex;
        address tokenA;
        address tokenB;
        bool smartCollateral;
        bool smartDebt;
        uint256 baseWithdrawalLimitInUSD;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    enum TYPE {
        TYPE_1,
        TYPE_2,
        TYPE_3,
        TYPE_4
    }

    struct Vault {
        address vault;
        TYPE vaultType;
        address supplyToken;
        address borrowToken;
        uint256 baseWithdrawalLimitInUSD;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    function setDexLimits(Dex memory dex_) internal {
        // Smart Collateral
        if (dex_.smartCollateral) {
            SupplyProtocolConfig memory protocolConfigTokenA_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);
        }

        // Smart Debt
        if (dex_.smartDebt) {
            BorrowProtocolConfig memory protocolConfigTokenA_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig memory protocolConfigTokenB_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenB_);
        }
    }

    function setVaultLimits(Vault memory vault_) internal {
        if (vault_.vaultType == TYPE.TYPE_1) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_1) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 30 * 1e2, // 30%
                expandDuration: 6 hours, // 6 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 35 * 1e2, // 35%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }
    }

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 3_320 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant weETH_USD_PRICE = 3_350 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_750 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant ezETH_USD_PRICE = 3_450 * 1e2;

    uint256 public constant BTC_USD_PRICE = 102_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 7.2 * 1e2;

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
