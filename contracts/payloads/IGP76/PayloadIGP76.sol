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

contract PayloadIGP76 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 76;

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

        // Action 1: Set oracles for T4 Vaults
        action1();

        // Action 2: Transfer 240k FLUID to Team Multisig
        action2();

        // Action 3: Set allowances from reserve contract
        action3();
    }

    /// @notice Action 1: Set limits for fSUSDs
    function action1() internal {
        {  // wsETH-ETH T4 Vault - 44
            address wsETH_ETH_T4_VAULT = getVaultAddress(44);
            uint256 ORACLE_wsETH_ETH = 77; // https://etherscan.io/address/0xc0aaB32BD6258773b43c0dC8E2049C6a4960c488#code

            // set oracle for wsETH-ETH T4 Vault
            IFluidVault(wsETH_ETH_T4_VAULT).updateOracle(ORACLE_wsETH_ETH);
        }

        { // cbBTC-wBTC T4 Vault - 51
            address cbBTC_wBTC_T4_VAULT = getVaultAddress(51);
            uint256 ORACLE_cbBTC_wBTC = 76; // https://etherscan.io/address/0x0fe9AAFf5B740061f6696f90cF489c0D6B6B4488#code

            // set oracle for cbBTC-wBTC T4 Vault
            IFluidVault(cbBTC_wBTC_T4_VAULT).updateOracle(ORACLE_cbBTC_wBTC);
        }

        {  // GHO-USDC T4 Vault - 61
            address GHO_USDC_T4_VAULT = getVaultAddress(61);
            uint256 ORACLE_GHO_USDC = 78; // https://etherscan.io/address/0xFE99a98E536c13f05E410F550bfE06fE55386e71#code

            // set oracle for GHO-USDC T4 Vault
            IFluidVault(GHO_USDC_T4_VAULT).updateOracle(ORACLE_GHO_USDC);
        }
    }

    /// @notice Action 2: Transfer 240k FLUID to Team Multisig
    function action2() internal {
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer INST to Team Multisig
        {   
            uint256 FLUID_AMOUNT = 240_000 * 1e18; // 240k FLUID
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(withdrawSignature, FLUID_ADDRESS, FLUID_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    /// @notice Action 3: Set allowances from reserve contract
    function action3() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        {
            // wBTC<>USDC
            address wBTC_USDC_VAULT = getVaultAddress(21);

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                wBTC_USDC_VAULT
            );

            protocols[0] = wBTC_USDC_VAULT;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (33_100 * 1e6);
        }

        {
            // fGHO
            uint256 allowance = IERC20(GHO_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_GHO_ADDRESS
            );

            protocols[1] = F_GHO_ADDRESS;
            tokens[1] = GHO_ADDRESS;
            amounts[1] = allowance + (200_000 * 1e18);
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }
}