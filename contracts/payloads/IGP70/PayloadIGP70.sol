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

contract PayloadIGP70 is PayloadIGPConstants, PayloadIGPHelpers {
    uint256 public constant PROPOSAL_ID = 70;

    // 
    uint256 public CBBTC_WBTC_NEW_CENTER_PRICE;
    bool public CBBTC_WBTC_SKIP_REBALANCE_TIME;
    bool public CBBTC_WBTC_SKIP_RANGE_CHANGE;

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

        // Action 1: Update cbBTC-wBTC min and max center price
        action1();

        // Action 2: Update cbBTC-wBTC rebalance time
        action2();

        // Action 3: Update cbBTC-wBTC range
        action3();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Team Multisig Actions      |
     * |__________________________________
     */
    function setState(
        uint256 cbBTC_wBTC_new_center_price,
        bool cbBTC_wBTC_skip_rebalance_time,
        bool cbBTC_wBTC_skip_range_change
    ) external {
        if (msg.sender != TEAM_MULTISIG) {
            revert("not-team-multisig");
        }

        CBBTC_WBTC_NEW_CENTER_PRICE = cbBTC_wBTC_new_center_price;
        CBBTC_WBTC_SKIP_REBALANCE_TIME = cbBTC_wBTC_skip_rebalance_time;
        CBBTC_WBTC_SKIP_RANGE_CHANGE = cbBTC_wBTC_skip_range_change;
    }

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Update cbBTC-wBTC min and max center price
    function action1() internal {
        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        uint256 newCenterPrice_ = PayloadIGP70(ADDRESS_THIS).CBBTC_WBTC_NEW_CENTER_PRICE();

        if (newCenterPrice_ == 420) return;

        require(
            newCenterPrice_ > 0.997 * 1e6 && newCenterPrice_ <= 0.998 * 1e6,
            "new-center-price-is-too-high"
        );

        // Update Center Price Limits between 0.3% to 0.2%
        uint256 minCenterPrice_ = (newCenterPrice_ * 1e27) / 1e6;
        uint256 maxCenterPrice_ = uint256(1e27 * 1e6) / newCenterPrice_;

        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateCenterPriceLimits(
            maxCenterPrice_,
            minCenterPrice_
        );
    }

    /// @notice Action 2: Update cbBTC-wBTC rebalance time
    function action2() internal {
        if (PayloadIGP70(ADDRESS_THIS).CBBTC_WBTC_SKIP_REBALANCE_TIME()) return;

        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateThresholdPercent(
            50 * 1e4,
            50 * 1e4,
            9 days,
            1
        );
    }

    /// @notice Action 3: Update cbBTC-wBTC range
    function action3() internal {
        if (PayloadIGP70(ADDRESS_THIS).CBBTC_WBTC_SKIP_RANGE_CHANGE()) return;

        address cbBTC_wBTC_DEX_ADDRESS = getDexAddress(3);

        IFluidDex(cbBTC_wBTC_DEX_ADDRESS).updateRangePercents(
            0.15 * 1e4,
            0.15 * 1e4,
            2 days
        );
    }
}
