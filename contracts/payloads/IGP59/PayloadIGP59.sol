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

contract PayloadIGP59 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 59;

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

        // Action 1: Update Dex Pool Deployment Logic
        action1();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Update Dex Pool Deployment Logic
    function action1() internal {
        address OLD_DEPLOYMENT_LOGIC = address(0x6779d9D2e8722724bb42328EE905911B64df7a21);
        address NEW_DEPLOYMENT_LOGIC = address(0x7db5101f12555bD7Ef11B89e4928061B7C567D27);
        DEX_FACTORY.setDexDeploymentLogic(OLD_DEPLOYMENT_LOGIC, false);
        DEX_FACTORY.setDexDeploymentLogic(NEW_DEPLOYMENT_LOGIC, true);
    }

    /// @notice Action 2: Update wBTC-cbBTC dex pool range
    function action2() internal {
        IFluidDex(getDexAddress(3)).updateRangePercents(0.075 * 1e4, 0.075 * 1e4, 4 hours);
    }

    /// @notice Action 3: Update iETHv2 Risk Ratio of Spark
    function action3() internal {
        uint8[] memory protocolIds_ = new uint8[](1);
        uint256[] memory newRiskRatios_ = new uint256[](1);

        protocolIds_[0] = 7; // Protocol Id of Spark: 7
        newRiskRatios_[0] = 90.5 * 1e4; // 90.5% or 90.5 * 1e4

        // Update max risky ratio of Spark
        IETHV2.updateMaxRiskRatio(protocolIds_, newRiskRatios_);
    }
}
