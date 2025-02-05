pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

import { IGovernorBravo } from "./interfaces/IGovernorBravo.sol";
import { ITimelock } from "./interfaces/ITimelock.sol";

import { IFluidLiquidityAdmin, AdminModuleStructs as FluidLiquidityAdminStructs } from "./interfaces/IFluidLiquidity.sol";
import { IFluidReserveContract } from "./interfaces/IFluidReserveContract.sol";

import { IFluidVaultFactory } from "./interfaces/IFluidVaultFactory.sol";
import { IFluidDexFactory } from "./interfaces/IFluidDexFactory.sol";

import { IFluidDex, IFluidAdminDex } from "./interfaces/IFluidDex.sol";
import { IFluidDexResolver } from "./interfaces/IFluidDex.sol";

import { IFluidVault } from "./interfaces/IFluidVault.sol";
import { IFluidVaultT1 } from "./interfaces/IFluidVault.sol";

import { IFTokenAdmin } from "./interfaces/IFToken.sol";
import { ILendingRewards } from "./interfaces/IFToken.sol";

import { IDSAV2 } from "./interfaces/IDSA.sol";

import { PayloadIGPConstants } from "./constants.sol";
import { PayloadIGPHelpers } from "./helpers.sol";


abstract contract PayloadIGPMain is PayloadIGPHelpers {
    /**
     * |
     * |     State Variables      |
     * |__________________________
     */
    /// @notice The unix time when the proposal was created
    uint40 internal proposalCreationTime_;

    /// @notice Time when the proposal will be executable
    uint40 internal executableTime_;

    /// @notice Actions that can be skipped
    mapping(uint256 => bool) internal skipAction_;

    /// @notice Modifier to check if an action can be skipped
    modifier isActionSkippable(uint256 action_) {
        // If function is not skippable, then execute
        if (!PayloadIGPMain(ADDRESS_THIS).actionStatus(action_)) {
            _;
        }
    }

     /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setActionsToSkip(
        uint256[] calldata actionsToSkip_
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        for (uint256 i = 0; i < actionsToSkip_.length; i++) {
            skipAction_[actionsToSkip_[i]] = true;
        }
    }

    // @notice Allows the team multisig to set a delay(max 5 days) for execution
    // @param executableUnixTime_ The unix time when the proposal will be executable
    function setExecutionDelay(uint256 executableUnixTime_) external {
        require(msg.sender == TEAM_MULTISIG, "not-team-multisig");
        // 9 days (4 days FLUID governance process + 5 days team multisig delay)
        require(executableUnixTime_ <= proposalCreationTime_ + 9 days, "execution delay exceeds 9 days from proposal creation");
        executableTime_ = uint40(executableUnixTime_);
    }


    /**
     * |
     * |     Proposal Structure           |
     * |__________________________________
     */

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

        require(proposedId == _PROPOSAL_ID(), "PROPOSAL_IS_NOT_SAME");

        proposalCreationTime_ = uint40(block.timestamp);
    }

    function execute() public virtual {
        require(address(this) == address(TIMELOCK), "not-valid-caller");
        require(PayloadIGPMain(ADDRESS_THIS).isProposalExecutable(), "proposal-not-executable");
    }

    function verifyProposal() public view virtual {}

    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */

    function _PROPOSAL_ID() internal view virtual returns(uint256) {
        return 0;
    }


    function isProposalExecutable() public view returns (bool) {
        return block.timestamp >= executableTime_ || executableTime_ == 0;
    }

    function getProposalCreationTime() public view returns (uint40) {
        return proposalCreationTime_;
    }

    function getExecutableTime() public view returns (uint256) {
        return executableTime_;
    }

    function actionStatus(uint256 action_) public view returns (bool) {
        return skipAction_[action_];
    }
}
