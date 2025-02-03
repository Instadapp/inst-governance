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
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    // @notice Action 1: Increase Expand Percent and Expand Duration for vaults
    function action1() internal {
        for (uint256 i = 11; i < 104; i++) {
            if (i == 1) {
                // Skip vaults
                continue;
            }
            increaseExpandConfig(i);
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

        uint256 expandPercentForSmartVault_ = 30 * 1e2; // 30%
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
}
