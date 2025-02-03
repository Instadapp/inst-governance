pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";
import {FluidProtocolTypes} from "../libraries/fluidProtocolTypes.sol";
import {DexSlotsLink} from "../libraries/dexSlotsLink.sol";

import {IGovernorBravo} from "../common/interfaces/IGovernorBravo.sol";
import {ITimelock} from "../common/interfaces/ITimelock.sol";

import {IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs} from "../common/interfaces/IFluidLiquidity.sol";
import {IFluidReserveContract} from "../common/interfaces/IFluidReserveContract.sol";

import {IFluidVaultFactory} from "../common/interfaces/IFluidVaultFactory.sol";
import {IFluidDexFactory} from "../common/interfaces/IFluidDexFactory.sol";

import {IFluidDex, IFluidAdminDex, IFluidDexResolver} from "../common/interfaces/IFluidDex.sol";

import {IFluidVault, IFluidVaultT1, IFluidSmartVault} from "../common/interfaces/IFluidVault.sol";

import {IFTokenAdmin, ILendingRewards} from "../common/interfaces/IFToken.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import {IERC20} from "../common/interfaces/IERC20.sol";
import {IProxy} from "../common/interfaces/IProxy.sol";
import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";

contract PayloadIGP82 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 82;

    bool public skipAction4;
    bool public skipAction7;
    bool public skipAction8;
    bool public skipAction9;

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

        // Action 1: Increase Expand Percent and Expand Duration for vaults
        action1();

        // Action 2: Increase withdrawal limits for vaults 24, 25, 26
        action2();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Increase Expand Percent and Expand Duration for vaults
    function action1() internal {
        // Increase Expand Percent and Expand Duration for vaults
        for (uint256 i = 11; i <= 105; i++) {
            if (
                (i >= 34 && i <= 43) || // Skipping the vaults that are deployed with old dex factory
                (i >= 63 && i <= 65) || // skipping the vault as this is not initialized yet
                i == 62 || // skipping old ETH-USDC T4
                i == 75 || // skipping old INST-ETH 2
                i == 87 || // Skipping the vault as this limits from dex to vault is not set T4, sUSDe-USDT<>sUSDe-USDT
                (i >= 100 && i <= 102) || // Skipping these USDC collateral based vaults as there limits will be set IGP-83
                (i >= 103 && i <= 105) // Skipping these vaults as they are just set with initial limits on IGP-81
            ) {
                // Skip vaults
                continue;
            }
            increaseExpandConfig(i);
        }
    }

    // @notice Action 2: Increase withdrawal limits for vaults 24, 25, 26
    function action2() internal {
        // Increase withdrawal limits for vaults 24, 25, 26
        
        { // ETH<>WBTC 24
            address vault_ = getVaultAddress(24);

            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_,
                supplyToken: ETH_ADDRESS,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: 7_500_000 // 7.5M
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        { // wstETH<>WBTC 25
            address vault_ = getVaultAddress(25);

            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_,
                supplyToken: wstETH_ADDRESS,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: 7_500_000 // 7.5M
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        { // weETH<>WBTC 26
            address vault_ = getVaultAddress(26);

            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_,
                supplyToken: weETH_ADDRESS,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 6 hours, // 6 hours
                baseWithdrawalLimitInUSD: 7_500_000 // 7.5M
            });

            setSupplyProtocolLimits(protocolConfig_);
        }
    }

    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */

    function getVaultType(address vault_) public view returns (uint vaultType_) {
        if (vault_.code.length == 0) {
            revert("vault-not-deployed");
        }
        try IFluidSmartVault(vault_).TYPE() returns (uint type_) {
            return type_;
        } catch {
            // if TYPE() is not available but address is valid vault id, it must be vault T1
            return FluidProtocolTypes.VAULT_T1_TYPE;
        }
    }

    function increaseExpandConfig(uint256 vaultId_) internal {
        address vault_ = getVaultAddress(vaultId_);
        uint256 vaultType_ = getVaultType(vault_);

        uint256 expandPercentForNormalVault_ = 50 * 1e2; // 50%
        uint256 expandDurationForNormalVault_ = 6 hours; // 6 hours

        uint256 expandPercentForSmartVault_ = 50 * 1e2; // 50%
        uint256 expandDurationForSmartVault_ = 6 hours; // 6 hours
        
        if (vaultType_ == FluidProtocolTypes.VAULT_T1_TYPE) {
            IFluidVaultT1.ConstantViews memory c_ = IFluidVaultT1(vault_).constantsView();
            getLiquiditySupplyDataAndSetExpandConfig(c_.supplyToken, vault_, expandPercentForNormalVault_, expandDurationForNormalVault_);
            getLiquidityBorrowDataAndSetExpandConfig(c_.borrowToken, vault_, expandPercentForNormalVault_, expandDurationForNormalVault_);
        } else {
            IFluidSmartVault.ConstantViews memory c_ = IFluidSmartVault(vault_).constantsView();

            // Collateral
            if (vaultType_ == FluidProtocolTypes.VAULT_T2_SMART_COL_TYPE || vaultType_ == FluidProtocolTypes.VAULT_T4_SMART_COL_SMART_DEBT_TYPE) {
                // Smart Collateral
                getDexSupplyDataAndSetExpandConfig(c_.supply, vault_, expandPercentForSmartVault_, expandDurationForSmartVault_);
            } else {
                // Normal Collateral
                getLiquiditySupplyDataAndSetExpandConfig(c_.supplyToken.token0, vault_, expandPercentForNormalVault_, expandDurationForNormalVault_);
            }

            // Debt
            if (vaultType_ == FluidProtocolTypes.VAULT_T3_SMART_DEBT_TYPE || vaultType_ == FluidProtocolTypes.VAULT_T4_SMART_COL_SMART_DEBT_TYPE) {
                // Smart Debt
                getDexBorrowDataAndSetExpandConfig(c_.borrow, vault_, expandPercentForSmartVault_, expandDurationForSmartVault_);
            } else  {
                // Normal Debt
                getLiquidityBorrowDataAndSetExpandConfig(c_.borrowToken.token0, vault_, expandPercentForNormalVault_, expandDurationForNormalVault_);
            }
        }
    }

    function getLiquiditySupplyDataAndSetExpandConfig(
        address token_,
        address user_,
        uint256 expandPercent_,
        uint256 expandDuration_
    ) internal {
        bytes32 _LIQUDITY_PROTOCOL_SUPPLY_SLOT = LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
            LiquiditySlotsLink.LIQUIDITY_USER_SUPPLY_DOUBLE_MAPPING_SLOT,
            user_,
            token_
        );

        uint256 userSupplyData_ = LIQUIDITY.readFromStorage(_LIQUDITY_PROTOCOL_SUPPLY_SLOT); 

        FluidLiquidityAdminStructs.UserSupplyConfig[] memory configs_ = new FluidLiquidityAdminStructs.UserSupplyConfig[](1);

        configs_[0] = FluidLiquidityAdminStructs.UserSupplyConfig({
            user: user_,
            token: token_,
            mode: uint8(userSupplyData_ & 1),
            expandPercent: expandPercent_,
            expandDuration: expandDuration_,
            baseWithdrawalLimit: BigMathMinified.fromBigNumber(
                (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }

    function getLiquidityBorrowDataAndSetExpandConfig(
        address token_,
        address user_,
        uint256 expandPercent_,
        uint256 expandDuration_
    ) internal {
        bytes32 _LIQUDITY_PROTOCOL_BORROW_SLOT = LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
            LiquiditySlotsLink.LIQUIDITY_USER_BORROW_DOUBLE_MAPPING_SLOT,
            user_,
            token_
        );

        uint256 userBorrowData_ = LIQUIDITY.readFromStorage(_LIQUDITY_PROTOCOL_BORROW_SLOT);

        FluidLiquidityAdminStructs.UserBorrowConfig[] memory configs_ = new FluidLiquidityAdminStructs.UserBorrowConfig[](1);

        configs_[0] = FluidLiquidityAdminStructs.UserBorrowConfig({
            user: user_,
            token: token_,
            mode: uint8(userBorrowData_ & 1),
            expandPercent: expandPercent_,
            expandDuration: expandDuration_,
            baseDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            ),
            maxDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    function getDexSupplyDataAndSetExpandConfig(
        address dex_,
        address user_,
        uint256 expandPercent_,
        uint256 expandDuration_
    ) internal {
        bytes32 _DEX_PROTOCOL_SUPPLY_SLOT = DexSlotsLink.calculateMappingStorageSlot(DexSlotsLink.DEX_USER_SUPPLY_MAPPING_SLOT, user_);

        uint256 userSupplyData_ = IFluidAdminDex(dex_).readFromStorage(_DEX_PROTOCOL_SUPPLY_SLOT); 

        IFluidAdminDex.UserSupplyConfig[] memory configs_ = new IFluidAdminDex.UserSupplyConfig[](1);

        configs_[0] = IFluidAdminDex.UserSupplyConfig({
            user: user_,
            expandPercent: expandPercent_,
            expandDuration: expandDuration_,
            baseWithdrawalLimit: BigMathMinified.fromBigNumber(
                (userSupplyData_ >> DexSlotsLink.BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });

        IFluidAdminDex(dex_).updateUserSupplyConfigs(configs_);
    }

    function getDexBorrowDataAndSetExpandConfig(
        address dex_,
        address user_,
        uint256 expandPercent_,
        uint256 expandDuration_
    ) internal {
        bytes32 _DEX_PROTOCOL_BORROW_SLOT = DexSlotsLink.calculateMappingStorageSlot(DexSlotsLink.DEX_USER_BORROW_MAPPING_SLOT, user_);

        uint256 userBorrowData_ = IFluidAdminDex(dex_).readFromStorage(_DEX_PROTOCOL_BORROW_SLOT); 

        IFluidAdminDex.UserBorrowConfig[] memory configs_ = new IFluidAdminDex.UserBorrowConfig[](1);

        configs_[0] = IFluidAdminDex.UserBorrowConfig({
            user: user_,
            expandPercent: expandPercent_,
            expandDuration: expandDuration_,
            baseDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> DexSlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            ),
            maxDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> DexSlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });

        IFluidAdminDex(dex_).updateUserBorrowConfigs(configs_);
    }

    // Token Prices Constants
    uint256 public constant ETH_USD_PRICE = 2_720 * 1e2;
    uint256 public constant wstETH_USD_PRICE = 3_250 * 1e2;
    uint256 public constant weETH_USD_PRICE = 2_950 * 1e2;
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
            token == USR_ADDRESS
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
