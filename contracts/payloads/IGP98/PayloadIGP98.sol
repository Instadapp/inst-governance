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

contract PayloadIGP98 is PayloadIGPMain {
    uint256 public constant PROPOSAL_ID = 98;

    function execute() public virtual override {
        super.execute();

        // Action 1: Update Range, center Price and Fee for USDC-USDT DEX
        action1();

        // Action 2: Update Range and Center Price for WBTC-cbBTC DEX
        action2();

        // Action 3: Update Limits for sUSDe-USDT and USDe-USDT DEXes
        action3();

        // Action 4: Update Vault & DEX Auth for FLUID-ETH / ETH Vault and FLUID-ETH DEX
        action4();

        // Action 5: Update Borrow Shares for GHO-USDC DEX
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

    // @notice Action 1: Update Range, center Price and Fee for USDC-USDT DEX
    function action1() internal isActionSkippable(1) {
        {
            address USDC_USDT_DEX = getDexAddress(2);
            {
                // USDC-USDT DEX
                {
                    IFluidDex(USDC_USDT_DEX).updateRangePercents(
                        0.15 * 1e4, // +0.15%
                        0.15 * 1e4, // -0.15%
                        5 days
                    );

                    // Non Rebalancing
                    IFluidDex(USDC_USDT_DEX).updateThresholdPercent(
                        0,
                        0,
                        16777215,
                        0
                    );

                    // Update center price address to 0.15%
                    IFluidDex(USDC_USDT_DEX).updateCenterPriceAddress(
                        147,
                        0.1e4,
                        5 days
                    );

                    address FeeHandler = 0x65454D16A39c7b5b52A67116FC1cf0a5e5942EFd;
                    // Add new handler as auth
                    DEX_FACTORY.setDexAuth(USDC_USDT_DEX, FeeHandler, false);

                    //Update Trading Fee
                    IFluidDex(USDC_USDT_DEX).updateFeeAndRevenueCut(
                        0.001 * 1e4, // 0.001%
                        25 * 1e4 // 25%
                    );
                }
            }
        }
    }

    // @notice Action 2: Update Range and Center Price for WBTC-cbBTC DEX
    function action2() internal isActionSkippable(2) {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        // Update Min & Max center prices from -0.15% to -0.1%
        uint256 minCenterPrice_ = (9985 * 1e27) / 10000;
        uint256 maxCenterPrice_ = (9990 * 1e27) / 10000;
        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
            maxCenterPrice_,
            minCenterPrice_
        );
    }

    // @notice Action 3: Update Limits for sUSDe-USDT and USDe-USDT DEXes
    function action3() internal isActionSkippable(3) {
        {
            address sUSDe_USDT_DEX = getDexAddress(15);
            {
                // Set max sypply shares
                IFluidDex(sUSDe_USDT_DEX).updateMaxSupplyShares(
                    37_500_000 * 1e18 // from 30M shares
                );
            }
        }

        {
            address USDe_USDT_DEX = getDexAddress(18);
            {
                // Set max supply shares
                IFluidDex(USDe_USDT_DEX).updateMaxSupplyShares(
                    17_500_000 * 1e18 // from 12.5M shares
                );
            }
        }

        {
            address USDC_USDT_CONCENTRATED_DEX = getDexAddress(34);
            {
                // Set max borrow shares
                IFluidDex(USDC_USDT_CONCENTRATED_DEX).updateMaxBorrowShares(
                    20_000_000 * 1e18
                );
            }
        }
    }

    // @notice Action 4: Update Vault & DEX Auth for FLUID-ETH / ETH Vault and FLUID-ETH DEX
    function action4() internal isActionSkippable(4) {
        address FLUID_ETH__ETH_VAULT = getVaultAddress(76);
        {
            VAULT_FACTORY.setVaultAuth(
                FLUID_ETH__ETH_VAULT,
                TEAM_MULTISIG,
                true
            );
        }
        address FLUID_ETH_DEX = getDexAddress(11);
        {
            DEX_FACTORY.setDexAuth(FLUID_ETH_DEX, TEAM_MULTISIG, true);
        }
    }

    // @notice Action 5: Update Borrow Shares for GHO-USDC DEX
    function action5() internal isActionSkippable(5) {
        address GHO_USDC_DEX = getDexAddress(4);
        {
            IFluidDex(GHO_USDC_DEX).updateMaxBorrowShares(11_000_000 * 1e18); // from 11M shares
        }
    }

    // @notice Action 6: Update borrow limits for sUSDe-USDT<>USDT vault
    function action6() internal isActionSkippable(6) {
        address sUSDe_USDT__USDT_VAULT = getVaultAddress(92);
        {
            // [TYPE 2] sUSDe-USDT<>USDT | smart collateral & debt
            Vault memory VAULT_sUSDe_USDT_USDT = Vault({
                vault: sUSDe_USDT__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 12_000_000, // $12M
                maxBorrowLimitInUSD: 25_000_000 // $25M
            });

            setVaultLimits(VAULT_sUSDe_USDT_USDT); // TYPE_2 => 92
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
            token == iUSD_ADDRESS
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
