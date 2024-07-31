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

    /// @notice updates the liquidation threshold to `liquidationThreshold_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateLiquidationThreshold(uint liquidationThreshold_) external;

    /// @notice updates the liquidation max limit to `liquidationMaxLimit_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateLiquidationMaxLimit(uint liquidationMaxLimit_) external;

    /// @notice updates the withdrawal gap to `withdrawGap_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateWithdrawGap(uint withdrawGap_) external;

    /// @notice updates the liquidation penalty to `liquidationPenalty_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateLiquidationPenalty(uint liquidationPenalty_) external;

    /// @notice updates the borrow fee to `borrowFee_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateBorrowFee(uint borrowFee_) external;
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

contract PayloadIGP34 {
    uint256 public constant PROPOSAL_ID = 34;

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

    ILite public constant LITE =
        ILite(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

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

        // Action 1: call executePayload on timelock contract to execute payload related to Lite & Fluid
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

        // Action 1: Add new Claim Module and update Default Implementation on Lite
        action1();

        // Action 2: Update v1.1.0 Vaults config
        action2();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Add new Claim Module and update Default Implementation on Lite
    function action1() internal {
        // set dummy implementation
        LITE.setDummyImplementation(0x35E7961BE97ccba901Cf14b73202d58f7a33d46d);

        // add Claim Module

        bytes4[] memory sigs_ = new bytes4[](1);
        sigs_[0] =  bytes4(keccak256("claimFromSpark()"));
        LITE.addImplementation(0xc10A855055Eb3939FCaA512253Ec3f671C4Ab839, sigs_);
        
        address(LITE).call(abi.encode(sigs_[0]));
    }

    /// @notice Action 2: Update v1.1.0 Vaults config
    function action2() internal {
        VaultConfig[] memory configs_ = new VaultConfig[](10);

        uint256 i;

        // ETH_USDC
        {
            configs_[i++] = VaultConfig({
                vault: 0x0C8C77B7FF4c2aF7F6CEBbe67350A490E3DD6cB3,
                collateralFactor: 87 * 1e2,
                liquidationThreshold: 92 * 1e2,
                liquidationMaxLimit: 95 * 1e2,
                liquidationPenalty: 1 * 1e2
            });
        }

        // ETH/USDT
        {
            configs_[i++] = VaultConfig({
                vault: 0xE16A6f5359ABB1f61cE71e25dD0932e3E00B00eB,
                collateralFactor: 87 * 1e2,
                liquidationThreshold: 92 * 1e2,
                liquidationMaxLimit: 95 * 1e2,
                liquidationPenalty: 2 * 1e2
            });
        }

        // WSTETH/ETH
        {
            configs_[i++] = VaultConfig({
                vault: 0x82B27fA821419F5689381b565a8B0786aA2548De,
                collateralFactor: 95 * 1e2,
                liquidationThreshold: 97 * 1e2,
                liquidationMaxLimit: 98 * 1e2,
                liquidationPenalty: 0.1 * 1e2
            });
        }
        
        // WSTETH/USDC
        {
            configs_[i++] = VaultConfig({
                vault: 0x1982CC7b1570C2503282d0A0B41F69b3B28fdcc3,
                collateralFactor: 82 * 1e2,
                liquidationThreshold: 88 * 1e2,
                liquidationMaxLimit: 92.5 * 1e2,
                liquidationPenalty: 2.5 * 1e2
            });
        }

        // WSTETH/USDT
        {
            configs_[i++] = VaultConfig({
                vault: 0xb4F3bf2d96139563777C0231899cE06EE95Cc946,
                collateralFactor: 82 * 1e2,
                liquidationThreshold: 88 * 1e2,
                liquidationMaxLimit: 92.5 * 1e2,
                liquidationPenalty: 3 * 1e2
            });
        }

        // WEETH/WSTETH
        {
            configs_[i++] = VaultConfig({
                vault: 0xeAEf563015634a9d0EE6CF1357A3b205C35e028D,
                collateralFactor: 94 * 1e2,
                liquidationThreshold: 96 * 1e2,
                liquidationMaxLimit: 97 * 1e2,
                liquidationPenalty: 1 * 1e2
            });
        }

        // SUSDE/USDC
        {
            configs_[i++] = VaultConfig({
                vault: 0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd,
                collateralFactor: 90 * 1e2,
                liquidationThreshold: 92 * 1e2,
                liquidationMaxLimit: 95 * 1e2,
                liquidationPenalty: 2 * 1e2
            });
        }

        // SUSDE/USDT
        {
            configs_[i++] = VaultConfig({
                vault: 0xBc345229C1b52e4c30530C614BB487323BA38Da5,
                collateralFactor: 90 * 1e2,
                liquidationThreshold: 92 * 1e2,
                liquidationMaxLimit: 95 * 1e2,
                liquidationPenalty: 2 * 1e2
            });
        }

        // WEETH/USDC
        {
            configs_[i++] = VaultConfig({
                vault: 0xF2c8F54447cbd591C396b0Dd7ac15FAF552d0FA4,
                collateralFactor: 77 * 1e2,
                liquidationThreshold: 82 * 1e2,
                liquidationMaxLimit: 90 * 1e2,
                liquidationPenalty: 3 * 1e2
            });
        }

        // WEETH/USDT
        {
            configs_[i++] = VaultConfig({
                vault: 0x92643E964CA4b2c165a95CA919b0A819acA6D5F1,
                collateralFactor: 77 * 1e2,
                liquidationThreshold: 82 * 1e2,
                liquidationMaxLimit: 90 * 1e2,
                liquidationPenalty: 4 * 1e2
            });
        }

        _updateVaultConfig(configs_);
    }

    /// Helpers ///
    struct VaultConfig {
        address vault;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationMaxLimit;
        uint256 liquidationPenalty;
    }

    function _updateVaultConfig(VaultConfig[] memory configs_) internal {
        for (uint i = 0; i < configs_.length; i++) {
            VaultConfig memory config_ = configs_[i];

            IFluidVaultT1 vault_ = IFluidVaultT1(address(0));
            vault_.updateCollateralFactor(config_.collateralFactor);
            vault_.updateLiquidationMaxLimit(config_.liquidationMaxLimit);
            vault_.updateLiquidationThreshold(config_.liquidationThreshold);
            vault_.updateLiquidationPenalty(config_.liquidationPenalty);
        }
    }
}
