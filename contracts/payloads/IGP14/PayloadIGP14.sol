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

    /// @notice updates the collateral factor to `collateralFactor_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateCollateralFactor(uint collateralFactor_) external;
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

contract PayloadIGP14 {
    uint256 public constant PROPOSAL_ID = 14;

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

    IstETHProtocol public constant STETH_PROTOCOL = IstETHProtocol(0x1F6B2bFDd5D1e6AdE7B17027ff5300419a56Ad6b);
    address public constant VAULT_WSTETH_ETH = 0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91;

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
        // Action 1: Update collateral factor for wstETH/ETH vault on fluid
        action1();

        // Action 2: Update fluid max risk ratio on lite
        action2();

        // Action 3: Update aggregated ratio on lite
        action3();

        // Action 4: Whitelisting address on stETH Redemption Protocol
        action4();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update collateral factor for wstETH/ETH vault on fluid
    function action1() internal {
        // Updating C.F from 91% to 93%
        IFluidVaultT1(VAULT_WSTETH_ETH).updateCollateralFactor(93 * 1e2); // 93% or 93 * 1e2
    }

    /// @notice Action 2: Update fluid max risk ratio on lite
    function action2() internal {
        uint8[] memory protocolIds_ = new uint8[](1);
        uint256[] memory newRiskRatios_ = new uint256[](1);

        protocolIds_[0] = 8; // Protocol Id of fluid: 8
        newRiskRatios_[0] = 92.5 * 1e4; // 92.5% or 92.5 * 1e4

        // Update max risky ratio of fluid from 91% to 92.5%
        LITE.updateMaxRiskRatio(protocolIds_, newRiskRatios_);
    }

    /// @notice Action 3: Update aggregated ratio on lite
    function action3() internal {

        // Update aggregated max risk ratio from 83.5% to 90%
        LITE.updateAggrMaxVaultRatio(90 * 1e4); // 90% or 90 * 1e4
    }

    /// @notice Action 4: Whitelisting address on stETH Redemption Protocol
    function action4() internal {
        STETH_PROTOCOL.setUserAllowed(0xA02744dc2245e84fF3e309bAdfb4e54Bb0EC2Cf8, true);
    }
}
