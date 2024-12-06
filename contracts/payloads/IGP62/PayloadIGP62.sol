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

import {IFluidDex} from "../common/interfaces/IFluidDex.sol";
import {IFluidDexResolver} from "../common/interfaces/IFluidDex.sol";

import {IFluidVault} from "../common/interfaces/IFluidVault.sol";
import {IFluidVaultT1} from "../common/interfaces/IFluidVault.sol";

import {IFTokenAdmin} from "../common/interfaces/IFToken.sol";
import {ILendingRewards} from "../common/interfaces/IFToken.sol";

import {IDSAV2} from "../common/interfaces/IDSA.sol";
import { IERC20 } from "../common/interfaces/IERC20.sol";

import {PayloadIGPConstants} from "../common/constants.sol";
import {PayloadIGPHelpers} from "../common/helpers.sol";

contract PayloadIGP62 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 62;

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

        // Action 1: Reduce limits old INST-ETH Dex Pool
        action1();

        // Action 2: Update cbBTC-wBTC dex pool min and max center price
        action2();
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

    /// @notice Action 1: Set fGHO lending rewards
    function action1() internal {
        address[] memory protocols = new address[](1);
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        {
            /// fUSDC
            IFTokenAdmin(F_GHO_ADDRESS).updateRewards(
                0x512Ac5b6Cf04f042486A198eDB3c28C6F2c6285A
            );

            uint256 allowance = IERC20(GHO_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_GHO_ADDRESS
            );

            protocols[0] = F_GHO_ADDRESS;
            tokens[0] = GHO_ADDRESS;
            amounts[0] = allowance + (70_000 * 1e18);
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /// @notice Action 2: Remove team multisig as auth from new pools and vaults
    function action2() internal {
        uint256 eth_usdc_dex_id = PayloadIGP62(ADDRESS_THIS).ETH_USDC_DEX_ID();
        uint256 eth_usdc_vault_id = PayloadIGP62(ADDRESS_THIS).ETH_USDC_VAULT_ID();
        uint256 inst_eth_dex_id = PayloadIGP62(ADDRESS_THIS).INST_ETH_DEX_ID();
        uint256 inst_eth_vault_id = PayloadIGP62(ADDRESS_THIS).INST_ETH_VAULT_ID();
        require(inst_eth_dex_id > 10 && inst_eth_vault_id > 75, "invalid-ids");
        require(eth_usdc_dex_id > 10 && eth_usdc_vault_id > 75, "invalid-ids");
        address INST_ETH_DEX_ADDRESS = getDexAddress(inst_eth_dex_id);
        address INST_ETH_VAULT_ADDRESS = getVaultAddress(inst_eth_vault_id);
        address ETH_USDC_DEX_ADDRESS = getDexAddress(eth_usdc_dex_id);
        address ETH_USDC_VAULT_ADDRESS = getVaultAddress(eth_usdc_vault_id);

       DEX_FACTORY.setDexAuth(INST_ETH_DEX_ADDRESS, TEAM_MULTISIG, false);
       VAULT_FACTORY.setVaultAuth(INST_ETH_VAULT_ADDRESS, TEAM_MULTISIG, false);

       DEX_FACTORY.setDexAuth(ETH_USDC_DEX_ADDRESS, TEAM_MULTISIG, false);
       VAULT_FACTORY.setVaultAuth(ETH_USDC_VAULT_ADDRESS, TEAM_MULTISIG, false);
    }
}
