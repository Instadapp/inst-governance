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

contract PayloadIGP74 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 74;

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

        // Action 1: Transfer MORPHO to Team Multisig
        action1();
    }

    /// @notice Action 1: Transfer MORPHO to Team Multisig
    function action1() internal {
        IERC20 MORPHO_ADDRESS = IERC20(0x58D97B57BB95320F9a05dC918Aef65434969c2B2);

        IDSAV2 IETH_V2_DSA = IDSAV2(0x9600A48ed0f931d0c422D574e3275a90D8b22745);

        string[] memory targets = new string[](2);
        bytes[] memory encodedSpells = new bytes[](2);

        string memory convertToNewMorphoSignature = "convertToNewMorpho()";
        string memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";


        // Spell 1: Convert Legacy Morpho
        {   
            targets[0] = "MORPHO-TOKEN-WRAPPER-A";
            encodedSpells[0] = abi.encodeWithSignature(convertToNewMorphoSignature);
        }

        // Spell 2: Transfer MORPHO to Team Multisig
        {   
            targets[1] = "BASIC-A";
            encodedSpells[1] = abi.encodeWithSignature(withdrawSignature, MORPHO_ADDRESS, type(uint256).max, TEAM_MULTISIG, 0, 0);
        }
        // Add Governance Timelock as an authorized auth on iETH v2 DSA
        IETHV2.addDSAAuth(address(this));

        // Cast the spells
        IETH_V2_DSA.cast(targets, encodedSpells, address(this));
    }
}
