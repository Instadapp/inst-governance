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

contract PayloadIGP77 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 77;

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG_2 ||
                address(this) == PROPOSER_AVO_MULTISIG_3 ||
                address(this) == PROPOSER_AVO_MULTISIG_4 ||
                address(this) == PROPOSER_AVO_MULTISIG_5,
            "msg.sender-not-allowed"
        );

        uint256 totalActions = 1;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        targets[0] = address(TIMELOCK);
        values[0] = 0;
        signatures[0] = "executePayload(address,string,bytes)";
        calldatas[0] = abi.encode(ADDRESS_THIS, "execute()", abi.encode());

        uint256 proposedId = GOVERNOR.propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );

        require(proposedId == PROPOSAL_ID, "PROPOSAL_IS_NOT_SAME");
    }

    function execute() external {
        require(address(this) == address(TIMELOCK), "not-valid-caller");

        // Action 1: Set launch limits for eBTC-cbBTC DEX and eBTC-cbBTC<>WBTC T2, eBTC<>cbBTC T1, eBTC<>wBTC T1 vaults
        action1();

        // Action 2: Set launch limits for lBTC-cbBTC DEX and lBTC-cbBTC<>WBTC T2 vault
        action2();

        // Action 3: Update wbBTC<>cbBTC DEX configs
        action3();

        // Action 4: Set initial limits for deUSD-USDC DEX and deUSDC-USDC<>USDT T2 vault
        action4();

    }
    
    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Set launch limits for eBTC-cbBTC DEX and eBTC-cbBTC<>WBTC T2, eBTC<>cbBTC T1, eBTC<>wBTC T1 vaults
    function action1() internal {
        address eBTC_cbBTC_DEX = getDexAddress(16);
        address eBTC_cbBTC__WBTC_VAULT = getVaultAddress(96);
        address eBTC__wBTC_VAULT = getVaultAddress(94);
        address eBTC__cbBTC_VAULT = getVaultAddress(95);

        {
            // eBTC-cbBTC DEX
            {
                // eBTC-cbBTC Dex
                Dex memory DEX_eBTC_cbBTC = Dex({
                    dex: eBTC_cbBTC_DEX,
                    tokenA: eBTC_ADDRESS,
                    tokenB: cbBTC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 20_000_000, // $20M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_eBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(
                    eBTC_cbBTC_DEX, 
                    TEAM_MULTISIG, 
                    false
                );
            }
        }

        {
            // [TYPE 2] eBTC-cbBTC<>WBTC | smart collateral & normal debt
            Vault memory VAULT_eBTC_cbBTC = Vault({
                vault: eBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 7_500_000 // $7.5M
            });

            setVaultLimits(VAULT_eBTC_cbBTC); // TYPE_2 => 96

            VAULT_FACTORY.setVaultAuth(
                eBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }

        {
            // [TYPE 1] eBTC<>cbBTC | normal collateral & normal debt
            Vault memory VAULT_eBTC_cbBTC = Vault({
                vault: eBTC__cbBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: eBTC_ADDRESS,
                borrowToken: cbBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 7_500_000 // $7.5M
            });

            setVaultLimits(VAULT_eBTC_cbBTC); // TYPE_1 => 95

            VAULT_FACTORY.setVaultAuth(
                eBTC__cbBTC_VAULT, 
                TEAM_MULTISIG, 
                false
            );
        }

        {
            // [TYPE 1] eBTC<>wBTC | normal collateral & normal debt
            Vault memory VAULT_eBTC_wBTC = Vault({
                vault: eBTC__wBTC_VAULT,
                vaultType: TYPE.TYPE_1,
                supplyToken: eBTC_ADDRESS,
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 5_000_000, // $5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 7_500_000 // $7.5M
            });

            setVaultLimits(VAULT_eBTC_wBTC); // TYPE_1 => 94

            VAULT_FACTORY.setVaultAuth(
                eBTC__wBTC_VAULT, 
                TEAM_MULTISIG, 
                false
            );
        }
    }

    // @notice Action 2: Set launch limits for lBTC-cbBTC DEX and lBTC-cbBTC<>WBTC T2 vault
    function action2() internal {
        address lBTC_cbBTC_DEX = getDexAddress(17);
        address lBTC_cbBTC__WBTC_VAULT = getVaultAddress(97);

        {
            // lBTC-cbBTC DEX
            {
                // lBTC-cbBTC Dex
                Dex memory DEX_lBTC_cbBTC = Dex({
                    dex: lBTC_cbBTC_DEX,
                    tokenA: lBTC_ADDRESS,
                    tokenB: cbBTC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 20_000_000, // $20M
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_lBTC_cbBTC); // Smart Collateral

                DEX_FACTORY.setDexAuth(
                    lBTC_cbBTC_DEX, 
                    TEAM_MULTISIG, 
                    false);
            }
        }

        {
            // [TYPE 2] lBTC-cbBTC<>WBTC | smart collateral & normal debt
            Vault memory VAULT_lBTC_cbBTC_wBTC = Vault({
                vault: lBTC_cbBTC__WBTC_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: WBTC_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 7_500_000 // $7.5M
            });

            setVaultLimits(VAULT_lBTC_cbBTC_wBTC); // TYPE_2 => 97

            VAULT_FACTORY.setVaultAuth(
                lBTC_cbBTC__WBTC_VAULT,
                TEAM_MULTISIG,
                false
            );
        }
    }

    // @notice Action 3: Update wbBTC<>cbBTC DEX configs
    function action3() internal {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        // updates the upper and lower range +-0.2%
        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(
            0.2 * 1e4,
            0.2 * 1e4,
            2 days
        );

        // update min/max center price limits to 0.2%
        uint256 minCenterPrice_ = (998 * 1e27) / 1000;
        uint256 maxCenterPrice_ = uint256(1e27 * 1000) / 998;
        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
            maxCenterPrice_,
            minCenterPrice_
        );
    }

    // @notice Action 4: Set launch limits for deUSD-USDC DEX and deUSD-USDC<>USDT T2 vault
    function action4() internal {
        address deUSD_USDC_DEX = getDexAddress(19);
        address deUSD_USDC__USDT_VAULT = getVaultAddress(98);

        {
            // deUSD-USDC DEX
            {
                // deUSD-USDC Dex
                Dex memory DEX_deUSD_USDC = Dex({
                    dex: deUSD_USDC_DEX,
                    tokenA: deUSD_ADDRESS,
                    tokenB: USDC_ADDRESS,
                    smartCollateral: true,
                    smartDebt: false,
                    baseWithdrawalLimitInUSD: 10_000, // $10k
                    baseBorrowLimitInUSD: 0, // $0
                    maxBorrowLimitInUSD: 0 // $0
                });
                setDexLimits(DEX_deUSD_USDC); // Smart Collateral

                DEX_FACTORY.setDexAuth(
                    deUSD_USDC_DEX, 
                    TEAM_MULTISIG, 
                    true);
            }
        }

        {
            // [TYPE 2] deUSD-USDC<>USDT | smart collateral & normal debt
            Vault memory VAULT_deUSD_USDC_USDT = Vault({
                vault: deUSD_USDC__USDT_VAULT,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS,
                baseWithdrawalLimitInUSD: 0,
                baseBorrowLimitInUSD: 8_000, // $8k
                maxBorrowLimitInUSD: 10_000 // $10k
            });

            setVaultLimits(VAULT_deUSD_USDC_USDT); // TYPE_2 => 98

            VAULT_FACTORY.setVaultAuth(
                deUSD_USDC__USDT_VAULT,
                TEAM_MULTISIG,
                true
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
        if (
            vault_.vaultType == TYPE.TYPE_3 || vault_.vaultType == TYPE.TYPE_1
        ) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (
            vault_.vaultType == TYPE.TYPE_2 || vault_.vaultType == TYPE.TYPE_1
        ) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours, // 12 hours
                baseBorrowLimitInUSD: vault_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: vault_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfig_);
        }
    }

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 3_330 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_950 * 1e2;
    uint256 public constant weETH_USD_PRICE = 3_550 * 1e2;
    uint256 public constant rsETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant weETHs_USD_PRICE = 3_750 * 1e2;
    uint256 public constant mETH_USD_PRICE = 3_850 * 1e2;

    uint256 public constant BTC_USD_PRICE = 99_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1.15 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1.02 * 1e2;

    uint256 public constant FLUID_USD_PRICE = 6 * 1e2;

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
        } else if (token == cbBTC_ADDRESS || token == WBTC_ADDRESS) {
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
        } else if (token == GHO_ADDRESS || token == USDe_ADDRESS) {
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
