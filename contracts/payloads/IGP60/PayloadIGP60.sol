pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

import { IGovernorBravo } from "../common/interfaces/IGovernorBravo.sol";
import { ITimelock } from "../common/interfaces/ITimelock.sol";

import { IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs } from "../common/interfaces/IFluidLiquidity.sol";
import { IFluidReserveContract } from "../common/interfaces/IFluidReserveContract.sol";

import { IFluidVaultFactory } from "../common/interfaces/IFluidVaultFactory.sol";
import { IFluidDexFactory } from "../common/interfaces/IFluidDexFactory.sol";

import { IFluidDex } from "../common/interfaces/IFluidDex.sol";
import { IFluidDexResolver } from "../common/interfaces/IFluidDex.sol";

import { IFluidVault } from "../common/interfaces/IFluidVault.sol";
import { IFluidVaultT1 } from "../common/interfaces/IFluidVault.sol";

import { IFTokenAdmin } from "../common/interfaces/IFToken.sol";
import { ILendingRewards } from "../common/interfaces/IFToken.sol";

import { IDSAV2 } from "../common/interfaces/IDSA.sol";

import { PayloadIGPConstants } from "../common/constants.sol";
import { PayloadIGPHelpers } from "../common/helpers.sol";

contract PayloadIGP60 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 60;

    // State
    uint256 public INST_ETH_VAULT_ID = 0;
    uint256 public INST_ETH_DEX_ID = 0;
    uint256 public ETH_USDC_DEX_ID = 0;
    uint256 public ETH_USDC_VAULT_ID = 0;

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG_2 ||
                address(PROPOSER_AVO_MULTISIG_3) == PROPOSER_AVO_MULTISIG_3,
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

        // Action 1: Set INST-ETH Dex Pool and INST-ETH_ETH Vault Limits
        action1();

        // Action 2: Set new ETH-USDC Dex Pool and ETH-USDC Vault Limits
        action2();

        // Action 3: Reduce limits old ETH-USDC Dex Pool
        action3();

        // Action 4: Update cbBTC-wBTC dex pool min and max center price
        action4();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        uint256 inst_eth_dex_id,
        uint256 inst_eth_vault_id,
        uint256 eth_usdc_dex_id,
        uint256 eth_usdc_vault_id
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        INST_ETH_DEX_ID = inst_eth_dex_id;
        INST_ETH_VAULT_ID = inst_eth_vault_id;
        ETH_USDC_DEX_ID = eth_usdc_dex_id;
        ETH_USDC_VAULT_ID = eth_usdc_vault_id;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Set new INST-ETH Dex Pool and INST-ETH_ETH Vault Limits
    function action1() internal {
        uint256 inst_eth_dex_id = PayloadIGP60(ADDRESS_THIS).INST_ETH_DEX_ID();
        uint256 inst_eth_vault_id = PayloadIGP60(ADDRESS_THIS).INST_ETH_VAULT_ID();
        require(inst_eth_dex_id > 10 && inst_eth_vault_id > 75, "invalid-ids");
        address INST_ETH_ADDRESS = getDexAddress(inst_eth_dex_id);
        address INST_ETH_VAULT_ADDRESS = getVaultAddress(inst_eth_vault_id);

        { // Set DEX Limits on Liquidity Layer
            Dex memory DEX_INST_ETH = Dex({
                dex: INST_ETH_ADDRESS,
                tokenA: INST_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: false,
                baseWithdrawalLimitInUSD: 10_000_000, // $10M
                baseBorrowLimitInUSD: 0, // $0
                maxBorrowLimitInUSD: 0 // $0
            });
            setDexLimits(DEX_INST_ETH); // Smart Collateral and debt

            DEX_FACTORY.setDexAuth(INST_ETH_ADDRESS, TEAM_MULTISIG, true);
        }

        {
            // [TYPE 2] INST-ETH  | ETH | Smart collateral & debt
            Vault memory VAULT_INST_ETH = Vault({
                vault: INST_ETH_VAULT_ADDRESS,
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: ETH_ADDRESS,
                baseWithdrawalLimitInUSD: 0, // set at Dex
                baseBorrowLimitInUSD: 200, // $200
                maxBorrowLimitInUSD: 300 // $300
            });

            setVaultLimits(VAULT_INST_ETH); // TYPE_2

            VAULT_FACTORY.setVaultAuth(
                INST_ETH_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    /// @notice Action 2: Set new ETH-USDC Dex Pool and ETH-USDC Vault Limits
    function action2() internal {
        uint256 eth_usdc_dex_id = PayloadIGP60(ADDRESS_THIS).ETH_USDC_DEX_ID();
        uint256 eth_usdc_vault_id = PayloadIGP60(ADDRESS_THIS).ETH_USDC_VAULT_ID();
        require(eth_usdc_dex_id > 10 && eth_usdc_vault_id > 75, "invalid-ids");
        address ETH_USDC_ADDRESS = getDexAddress(eth_usdc_dex_id);
        address ETH_USDC_VAULT_ADDRESS = getVaultAddress(eth_usdc_vault_id);

        { // Set DEX Limits on Liquidity Layer
            Dex memory DEX_ETH_USDC = Dex({
                dex: ETH_USDC_ADDRESS,
                tokenA: ETH_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 15_000_000, // $15M
                baseBorrowLimitInUSD: 10_000_000, // $10M
                maxBorrowLimitInUSD: 12_000_000 // $12M
            });
            setDexLimits(DEX_ETH_USDC); // Smart Collateral and debt

            DEX_FACTORY.setDexAuth(ETH_USDC_ADDRESS, TEAM_MULTISIG, true);
        }

        {
            // Set Team Multisig Auth on new ETH-USDC smart collateral and debt vault
            VAULT_FACTORY.setVaultAuth(
                ETH_USDC_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    /// @notice Action 3: Reduce limits old ETH-USDC Dex Pool
    function action3() internal {
        address ETH_USDC_ADDRESS = getDexAddress(5);
        address ETH_USDC_VAULT_ADDRESS = getVaultAddress(62);

        { // Set DEX Limits on Liquidity Layer
            Dex memory DEX_ETH_USDC = Dex({
                dex: ETH_USDC_ADDRESS,
                tokenA: ETH_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 1000, // $1000
                baseBorrowLimitInUSD: 800, // $800
                maxBorrowLimitInUSD: 1000 // $1000
            });
            setDexLimits(DEX_ETH_USDC); // Smart Collateral and debt

            DEX_FACTORY.setDexAuth(ETH_USDC_ADDRESS, TEAM_MULTISIG, true);
        }

        { // Set Team Multisig Auth on old ETH-USDC smart collateral and debt vault
            VAULT_FACTORY.setVaultAuth(
                ETH_USDC_VAULT_ADDRESS,
                TEAM_MULTISIG,
                true
            );
        }
    }

    /// @notice Action 4: Update cbBTC-wBTC dex pool min and max center price
    function action4() internal {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        uint256 maxCenterPrice_ = 0.997 * 1e27;
        uint256 minCenterPrice_ = 1.0030090270812437 * 1e27;
        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(maxCenterPrice_, minCenterPrice_);
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
        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours, // 12 hours
                baseWithdrawalLimitInUSD: vault_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
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
    uint256 public constant ETH_USD_PRICE = 3_850 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 4_550 * 1e2;
    uint256 public constant weETH_USD_PRICE = 4_050 * 1e2;

    uint256 public constant BTC_USD_PRICE = 99_000 * 1e2;

    uint256 public constant STABLE_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDe_USD_PRICE = 1 * 1e2;
    uint256 public constant sUSDs_USD_PRICE = 1 * 1e2;
    
    uint256 public constant INST_USD_PRICE = 7 * 1e2;

    function getRawAmount(
        address token,
        uint256 amount,
        uint256 amountInUSD,
        bool isSupply
    ) public override view returns (uint256) {
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
        } else if (token == cbBTC_ADDRESS || token == WBTC_ADDRESS) {
            usdPrice = BTC_USD_PRICE;
            decimals = 8;
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
            usdPrice = INST_USD_PRICE;
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
