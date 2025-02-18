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

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";
import {PayloadIGPMain} from "../common/main.sol";

contract PayloadIGP85 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 85;

    address public USDC_USDT_REWARDS;

    function execute() public virtual override {
        super.execute();

        // Action 1: Set launch limits for cbBTC-USDT DEX T4 Vault
        action1();

        // Action 2: Set dust limits for cbBTC-ETH DEX T4 vault
        action2();

        // Action 3: Update rewards for fUSDC, fUSDT
        action3();

        // Action 4: Constrict BOLD DEX
        action4();

        // Action 5: Set Launch Limits for USD0-USDC & fxUSD-USDC
        action5();

        // Action 6: Set Rebalancers for USD0-USDC & fxUSD-USDC
        action6();

        // Action 7: Increase weETH-ETH Supply Limits
        action7();
    }

    function verifyProposal() public view override {}

    function _PROPOSAL_ID() internal view override returns (uint256) {
        return PROPOSAL_ID;
    }

    /**
     * |
     * |    Team Multisig Function        |
     * |__________________________________
     */

    function setState(address USDC_USDT_REWARDS_) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }
        USDC_USDT_REWARDS = USDC_USDT_REWARDS_;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set launch limits for cbBTC-USDT DEX T4 Vault
    function action1() internal isActionSkippable(1) {
        address cbBTC_USDT_DEX_ADDRESS = getDexAddress(22);

        {
            // launch limits
            Dex memory DEX_cbBTC_USDT = Dex({
                dex: cbBTC_USDT_DEX_ADDRESS,
                tokenA: cbBTC_ADDRESS,
                tokenB: USDT_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 15_000_000, // $15M
                baseBorrowLimitInUSD: 15_000_000, // $15M
                maxBorrowLimitInUSD: 20_000_000 // $20M
            });
            setDexLimits(DEX_cbBTC_USDT); // Smart Collateral & Smart Debt

            DEX_FACTORY.setDexAuth(
                cbBTC_USDT_DEX_ADDRESS,
                TEAM_MULTISIG,
                false
            );
        }

        {
            address cbBTC_USDT__cbBTC_USDT_VAULT_ADRESS = getVaultAddress(105);

            VAULT_FACTORY.setVaultAuth(
                cbBTC_USDT__cbBTC_USDT_VAULT_ADRESS,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 2: Set dust limits for cbBTC-ETH DEX T4 vault
    function action2() internal isActionSkippable(2) {
        address cbBTC_ETH_DEX_ADDRESS = getDexAddress(26);

        {
            // dust limits
            Dex memory DEX_cbBTC_ETH = Dex({
                dex: cbBTC_ETH_DEX_ADDRESS,
                tokenA: cbBTC_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 10_000, // $10k
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });
            setDexLimits(DEX_cbBTC_ETH); // Smart Collateral & Smart Debt

            DEX_FACTORY.setDexAuth(cbBTC_ETH_DEX_ADDRESS, TEAM_MULTISIG, true);
        }

        {
            address cbBTC_ETH__cbBTC_ETH_VAULT_ADRESS = getVaultAddress(106);

            // Set team multisig as vault auth for cbBTC-ETH T4 Vault
            VAULT_FACTORY.setVaultAuth(
                cbBTC_ETH__cbBTC_ETH_VAULT_ADRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    // @notice Action 3: Update rewards for fUSDC, fUSDT
    function action3() internal isActionSkippable(3) {
        address REWARDS_CONTRACT = PayloadIGP85(ADDRESS_THIS)
            .USDC_USDT_REWARDS();
        if (REWARDS_CONTRACT == address(0)) return; // skip the update if the rewards contract is not set

        IFTokenAdmin(F_USDC).updateRewards(REWARDS_CONTRACT);
        IFTokenAdmin(F_USDT).updateRewards(REWARDS_CONTRACT);
    }

    // @notice Action 4: Constrict BOLD DEX
    function action4() internal isActionSkippable(4) {
        address USDC_BOLD_DEX = getDexAddress(25);
        {
            // USDC-BOLD DEX
            {
                setSupplyProtocolLimitsPaused(USDC_BOLD_DEX, USDC_ADDRESS);

                setSupplyProtocolLimitsPaused(USDC_BOLD_DEX, BOLD_ADDRESS);

                DEX_FACTORY.setDexAuth(USDC_BOLD_DEX, TEAM_MULTISIG, false);
            }
        }

        {
            // minimize supply shares
            IFluidDex(USDC_BOLD_DEX).updateMaxSupplyShares(1);
        }

        {
            // minimize borrow shares
            IFluidDex(USDC_BOLD_DEX).updateMaxBorrowShares(1);
        }

        {
            // Pause user supply and borrow
            address[] memory supplyTokens = new address[](2);
            supplyTokens[0] = USDC_ADDRESS;
            supplyTokens[1] = BOLD_ADDRESS;

            address[] memory borrowTokens = new address[](0);

            // Pause the user operations
            LIQUIDITY.pauseUser(USDC_BOLD_DEX, supplyTokens, borrowTokens);
        }
    }

    // @notice Action 5: Set Launch Limits for USD0-USDC & fxUSD-USDC
    function action5() internal isActionSkippable(5) {
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
                    baseWithdrawalLimitInUSD: 10_000_000, // $10M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_USD0_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(USD0_USDC_DEX, TEAM_MULTISIG, false);
            }

            IFluidDex(USD0_USDC_DEX).updateMaxSupplyShares(
                7_500_000 * 1e18 // $15M
            );
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
                    baseWithdrawalLimitInUSD: 10_000_000, // $10M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_fxUSD_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(fxUSD_USDC_DEX, TEAM_MULTISIG, false);
            }

            IFluidDex(fxUSD_USDC_DEX).updateMaxSupplyShares(
                7_500_000 * 1e18 // $15M
            );
        }
    }
    // @notice Action 6: Set Rebalancers for USD0-USDC & fxUSD-USDC
    function action6() internal isActionSkippable(6) {
        {
            address fSL21_USD0_USDC = getSmartLendingAddress(21);

            // set rebalancer at fSL21 to reserve contract proxy
            ISmartLendingAdmin(fSL21_USD0_USDC).updateRebalancer(
                address(FLUID_RESERVE)
            );
        }

        {
            address fSL22_FXUSD_USDC = getSmartLendingAddress(22);

            // set rebalancer at fSL22 to reserve contract proxy
            ISmartLendingAdmin(fSL22_FXUSD_USDC).updateRebalancer(
                address(FLUID_RESERVE)
            );
        }
    }

    // @notice Action 7: Increase weETH-ETH Supply Limits
    function action7() internal isActionSkippable(7) {
        address WEETH_ETH_DEX_ADDRESS = getDexAddress(9);

        { // Increase Max Supply Shares
            IFluidDex(WEETH_ETH_DEX_ADDRESS).updateMaxSupplyShares(
                9_000 * 1e18 // 9k shares
            );
        }
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
            SupplyProtocolConfig
                memory protocolConfigTokenA_ = SupplyProtocolConfig({
                    protocol: dex_.dex,
                    supplyToken: dex_.tokenA,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 1 hours, // 1 hour
                    baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
                });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig
                memory protocolConfigTokenB_ = SupplyProtocolConfig({
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
            BorrowProtocolConfig
                memory protocolConfigTokenA_ = BorrowProtocolConfig({
                    protocol: dex_.dex,
                    borrowToken: dex_.tokenA,
                    expandPercent: 50 * 1e2, // 50%
                    expandDuration: 1 hours, // 1 hour
                    baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                    maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
                });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig
                memory protocolConfigTokenB_ = BorrowProtocolConfig({
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
