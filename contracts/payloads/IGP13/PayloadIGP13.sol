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

interface ILite {
    function setAdmin(address newAdmin) external;

    function getAdmin() external view returns (address);

    function removeImplementation(address implementation_) external;

    function addImplementation(
        address implementation_,
        bytes4[] calldata sigs_
    ) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function updateMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) external;

    function updateAggrMaxVaultRatio(uint256 newAggrMaxVaultRatio_) external;
}

interface IFluidVaultT1 {
    /// @notice updates the Vault oracle to `newOracle_`. Must implement the FluidOracle interface.
    function updateOracle(address newOracle_) external;

    /// @notice updates the all Vault core settings according to input params.
    /// All input values are expected in 1e2 (1% = 100, 100% = 10_000).
    function updateCoreSettings(
        uint256 supplyRateMagnifier_,
        uint256 borrowRateMagnifier_,
        uint256 collateralFactor_,
        uint256 liquidationThreshold_,
        uint256 liquidationMaxLimit_,
        uint256 withdrawGap_,
        uint256 liquidationPenalty_,
        uint256 borrowFee_
    ) external;

    /// @notice updates the allowed rebalancer to `newRebalancer_`.
    function updateRebalancer(address newRebalancer_) external;

    /// @notice updates the supply rate magnifier to `supplyRateMagnifier_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateSupplyRateMagnifier(uint supplyRateMagnifier_) external;
}

contract PayloadIGP13 {
    uint256 public constant PROPOSAL_ID = 13;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    address public constant PROPOSER_AVO_MULTISIG =
        0x059A94A72951c0ae1cc1CE3BF0dB52421bbE8210;

    IGovernorBravo public constant GOVERNOR =
        IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public immutable TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG = 
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    ILite public constant LITE =
        ILite(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

    address public constant WITHDRAWALS_MODULE =
        0x6A64A3E0af38279ac7455c85b2C683f5621cE2e7;
    address public constant FLUID_STETH_MODULE =
        0x0F1679FB1d5B2981423c757e8ea91979fabDB2D1;

    address public constant DUMMY_IMPLEMENTATION =
        0xd58ca26C8e888Fb628753F08816bED4a07d0E4af;

    address public constant VAULT_WEETH_WSTETH = 0x40D9b8417E6E1DcD358f04E3328bCEd061018A82;
    address public constant VAULT_WEETH_WSTETH_ORACLE = 0x322F7FCEA001bEBB63413f42B0028E5A81b933EF;

    constructor() {
        ADDRESS_THIS = address(this);
    }

    function propose(string memory description) external {
        require(
            (
                msg.sender == PROPOSER || 
                msg.sender == TEAM_MULTISIG
            ) || 
            address(this) == PROPOSER_AVO_MULTISIG,
            "msg.sender-not-allowed"
        );

        uint256 totalActions = 1;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        // Action 1: call executePayload on timelock contract to execute payload related to lite & fluid
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
        // Action 1: Update withdraw implementation
        action1();

        // Action 2: Add Fluid stETH Implementation
        action2();

        // Action 3: Set dummy implementations
        action3();

        // Action 4: Change oracle address of weETH/wstETH vault
        action4();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update withdraw implementation
    function action1() internal {
        // remove implementation
        LITE.removeImplementation(WITHDRAWALS_MODULE);

        // add same implementation with update signature
        LITE.addImplementation(WITHDRAWALS_MODULE, withdrawalsSigs());
    }

    /// @notice Action 2: Add Fluid stETH Implementation
    function action2() internal {
        LITE.addImplementation(FLUID_STETH_MODULE, fluidStETHSigs());
    }

    /// @notice Action 3: Change dummy implementation.
    function action3() internal {
        LITE.setDummyImplementation(DUMMY_IMPLEMENTATION);
    }

    /// @notice Action 4: Change oracle address of weETH/wstETH vault
    function action4() internal {
        IFluidVaultT1(VAULT_WEETH_WSTETH).updateOracle(VAULT_WEETH_WSTETH_ORACLE);
    }

    /***********************************|
    |          Function Signatures      |
    |__________________________________*/
    
    function withdrawalsSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](2);
        sigs_[0] = bytes4(keccak256("paybackDebt(uint8)"));
        sigs_[1] = bytes4(keccak256("claimEthWithdrawal(uint256,uint8)"));
    }

    function fluidStETHSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](3);
        sigs_[0] = bytes4(keccak256("queueSteth(uint8,uint256,uint256,uint256)"));
        sigs_[1] = bytes4(keccak256("claimSteth(uint256)"));
        sigs_[2] = bytes4(keccak256("claimStethAndPaybackFluid(uint256)"));
    }
}
