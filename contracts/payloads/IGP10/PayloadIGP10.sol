pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IGovernorBravo {
    function _acceptAdmin() external;

    function _setVotingDelay(uint newVotingDelay) external;

    function _setVotingPeriod(uint newVotingPeriod) external;

    function _acceptAdminOnTimelock() external;

    function _setImplementation(address implementation_) external;

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint);

    function admin() external view returns (address);

    function pendingAdmin() external view returns (address);

    function timelock() external view returns (address);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);
}

interface ITimelock {
    function acceptAdmin() external;

    function setDelay(uint delay_) external;

    function setPendingAdmin(address pendingAdmin_) external;

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external returns (bytes32);

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) external payable returns (bytes memory);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function delay() external view returns (uint256);
}

interface IInstaIndex {
    function changeMaster(address _newMaster) external;
    function updateMaster() external;
    function master() external view returns (address);
}

interface AdminModuleStructs {
    struct AddressBool {
        address addr;
        bool value;
    }

    struct AddressUint256 {
        address addr;
        uint256 value;
    }

    struct RateDataV1Params {
        address token;
        uint256 kink;
        uint256 rateAtUtilizationZero;
        uint256 rateAtUtilizationKink;
        uint256 rateAtUtilizationMax;
    }

    struct RateDataV2Params {
        address token;
        uint256 kink1;
        uint256 kink2;
        uint256 rateAtUtilizationZero;
        uint256 rateAtUtilizationKink1;
        uint256 rateAtUtilizationKink2;
        uint256 rateAtUtilizationMax;
    }

    struct TokenConfig {
        address token;
        uint256 fee;
        uint256 threshold;
    }

    struct UserSupplyConfig {
        address user;
        address token;
        uint8 mode;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseWithdrawalLimit;
    }

    struct UserBorrowConfig {
        address user;
        address token;
        uint8 mode;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseDebtCeiling;
        uint256 maxDebtCeiling;
    }
}

interface IFluidLiquidityAdmin {
    /// @notice adds/removes auths. Auths generally could be contracts which can have restricted actions defined on contract.
    ///         auths can be helpful in reducing governance overhead where it's not needed.
    /// @param authsStatus_ array of structs setting allowed status for an address.
    ///                     status true => add auth, false => remove auth
    function updateAuths(AdminModuleStructs.AddressBool[] calldata authsStatus_) external;

    /// @notice adds/removes guardians. Only callable by Governance.
    /// @param guardiansStatus_ array of structs setting allowed status for an address.
    ///                         status true => add guardian, false => remove guardian
    function updateGuardians(AdminModuleStructs.AddressBool[] calldata guardiansStatus_) external;

    /// @notice changes the revenue collector address (contract that is sent revenue). Only callable by Governance.
    /// @param revenueCollector_  new revenue collector address
    function updateRevenueCollector(address revenueCollector_) external;

    /// @notice changes current status, e.g. for pausing or unpausing all user operations. Only callable by Auths.
    /// @param newStatus_ new status
    ///        status = 2 -> pause, status = 1 -> resume.
    function changeStatus(uint256 newStatus_) external;

    /// @notice                  update tokens rate data version 1. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV1Params with rate data to set for each token
    function updateRateDataV1s(AdminModuleStructs.RateDataV1Params[] calldata tokensRateData_) external;

    /// @notice                  update tokens rate data version 2. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV2Params with rate data to set for each token
    function updateRateDataV2s(AdminModuleStructs.RateDataV2Params[] calldata tokensRateData_) external;

    /// @notice updates token configs: fee charge on borrowers interest & storage update utilization threshold.
    ///         Only callable by Auths.
    /// @param tokenConfigs_ contains token address, fee & utilization threshold
    function updateTokenConfigs(AdminModuleStructs.TokenConfig[] calldata tokenConfigs_) external;

    /// @notice updates user classes: 0 is for new protocols, 1 is for established protocols.
    ///         Only callable by Auths.
    /// @param userClasses_ struct array of uint256 value to assign for each user address
    function updateUserClasses(AdminModuleStructs.AddressUint256[] calldata userClasses_) external;

    /// @notice sets user supply configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userSupplyConfigs_ struct array containing user supply config, see `UserSupplyConfig` struct for more info
    function updateUserSupplyConfigs(AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_) external;

    /// @notice setting user borrow configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userBorrowConfigs_ struct array containing user borrow config, see `UserBorrowConfig` struct for more info
    function updateUserBorrowConfigs(AdminModuleStructs.UserBorrowConfig[] memory userBorrowConfigs_) external;

    /// @notice pause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to pause operations for
    /// @param supplyTokens_  token addresses to pause withdrawals for
    /// @param borrowTokens_  token addresses to pause borrowings for
    function pauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external;

    /// @notice unpause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to unpause operations for
    /// @param supplyTokens_  token addresses to unpause withdrawals for
    /// @param borrowTokens_  token addresses to unpause borrowings for
    function unpauseUser(address user_, address[] calldata supplyTokens_, address[] calldata borrowTokens_) external;

    /// @notice         collects revenue for tokens to configured revenueCollector address.
    /// @param tokens_  array of tokens to collect revenue for
    /// @dev            Note that this can revert if token balance is < revenueAmount (utilization > 100%)
    function collectRevenue(address[] calldata tokens_) external;

    /// @notice gets the current updated exchange prices for n tokens and updates all prices, rates related data in storage.
    /// @param tokens_ tokens to update exchange prices for
    /// @return supplyExchangePrices_ new supply rates of overall system for each token
    /// @return borrowExchangePrices_ new borrow rates of overall system for each token
    function updateExchangePrices(
        address[] calldata tokens_
    ) external returns (uint256[] memory supplyExchangePrices_, uint256[] memory borrowExchangePrices_);
}

interface IstETHProtocol {
    /// @notice                  initializes the contract with `owner_` as owner
    function initialize(address owner_) external;

    /// @notice                   Sets an address as allowed user or not. Only callable by auths.
    /// @param user_              address to set allowed value for
    /// @param allowed_           bool flag for whether address is allowed as user or not
    function setUserAllowed(address user_, bool allowed_) external;

    /// @notice                   Sets `maxLTV` to `maxLTV_` (in 1e2: 1% = 100, 100% = 10000). Must be > 0 and < 100%.
    function setMaxLTV(uint16 maxLTV_) external;

    /// @notice                   Sets an address as allowed guardian or not. Only callable by owner.
    /// @param guardian_          address to set guardian value for
    /// @param allowed_           bool flag for whether address is allowed as guardian or not
    function setGuardian(address guardian_, bool allowed_) external;
}

contract PayloadIGP10 {
    uint256 public constant PROPOSAL_ID = 10;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    IGovernorBravo public constant GOVERNOR =
        IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public constant TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public constant TEAM_MULTISIG = 
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    address public immutable ADDRESS_THIS;
    
    IFluidLiquidityAdmin public constant LIQUIDITY = IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() {
        ADDRESS_THIS = address(this);
    }

    function propose(string memory description) external {
        require(msg.sender == PROPOSER || msg.sender == TEAM_MULTISIG, "msg.sender-not-proposer-or-multisig");

        uint256 totalActions = 1;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        // Action 1: call executePayload on timelock contract to execute payload related to Fluid
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

        // Action 1: Update rate current for USDC market
        action1();

        // Action 1: Update rate current for USDT market
        action2();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update rate current for USDC market
    function action1() internal {
       AdminModuleStructs.RateDataV2Params[] memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

       params_[0] = AdminModuleStructs.RateDataV2Params({
            token: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
            kink1: 80 * 1e2, // 80%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 18 * 1e2, // 18%
            rateAtUtilizationMax: 33.34 * 1e2 // 33.34%
       });

       LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 2: Update rate current for USDT market
    function action2() internal {
       AdminModuleStructs.RateDataV2Params[] memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

       params_[0] = AdminModuleStructs.RateDataV2Params({
            token: 0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
            kink1: 80 * 1e2, // 80%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 12 * 1e2, // 12%
            rateAtUtilizationKink2: 18 * 1e2, // 18%
            rateAtUtilizationMax: 33.34 * 1e2 // 33.34%
       });

       LIQUIDITY.updateRateDataV2s(params_);
    }
}
