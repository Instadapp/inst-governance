pragma solidity >=0.7.0;
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
        uint256 maxUtilization;
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

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(
        address implementation_,
        bytes4[] calldata sigs_
    ) external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(
        address impl_
    ) external view returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
}

interface IInstaAccountV2Implementations {
    function setDefaultImplementation(address _defaultImplementation) external;
}

contract PayloadIGP33 {
    uint256 public constant PROPOSAL_ID = 33;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    address public constant PROPOSER_AVO_MULTISIG =
        0x059A94A72951c0ae1cc1CE3BF0dB52421bbE8210;

    address public constant PROPOSER_AVO_MULTISIG_2 =
        0x9efdE135CA4832AbF0408c44c6f5f370eB0f35e8;

    address public constant PROPOSER_AVO_MULTISIG_3 = 
        0x5C43AAC965ff230AC1cF63e924D0153291D78BaD;

    IGovernorBravo public constant GOVERNOR =
        IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public immutable TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    IInstaAccountV2Implementations public constant INSTA_ACCOUNT_V2_IMPLEMENTATIONS = IInstaAccountV2Implementations(0xCBA828153d3a85b30B5b912e1f2daCac5816aE9D);

    constructor() {
        ADDRESS_THIS = address(this);
    }

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

        // Action 1: call executePayload on timelock contract to execute payload related to DSA
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

        // Action 1: Update Default Implementation of DSAv2
        action1();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update Default Implementation of DSAv2
    function action1() internal {
        address NEW_DEFAULT_IMPLEMENTATION = address(0x8F4a8675Ea3a069D1D8280Bd19B802430f8F53be);

        INSTA_ACCOUNT_V2_IMPLEMENTATIONS.setDefaultImplementation(NEW_DEFAULT_IMPLEMENTATION);
    }
}
