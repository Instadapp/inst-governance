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

interface IFluidLiquidityAdmin {
    /// @notice adds/removes auths. Auths generally could be contracts which can have restricted actions defined on contract.
    ///         auths can be helpful in reducing governance overhead where it's not needed.
    /// @param authsStatus_ array of structs setting allowed status for an address.
    ///                     status true => add auth, false => remove auth
    function updateAuths(
        AdminModuleStructs.AddressBool[] calldata authsStatus_
    ) external;

    /// @notice adds/removes guardians. Only callable by Governance.
    /// @param guardiansStatus_ array of structs setting allowed status for an address.
    ///                         status true => add guardian, false => remove guardian
    function updateGuardians(
        AdminModuleStructs.AddressBool[] calldata guardiansStatus_
    ) external;

    /// @notice changes the revenue collector address (contract that is sent revenue). Only callable by Governance.
    /// @param revenueCollector_  new revenue collector address
    function updateRevenueCollector(address revenueCollector_) external;

    /// @notice changes current status, e.g. for pausing or unpausing all user operations. Only callable by Auths.
    /// @param newStatus_ new status
    ///        status = 2 -> pause, status = 1 -> resume.
    function changeStatus(uint256 newStatus_) external;

    /// @notice                  update tokens rate data version 1. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV1Params with rate data to set for each token
    function updateRateDataV1s(
        AdminModuleStructs.RateDataV1Params[] calldata tokensRateData_
    ) external;

    /// @notice                  update tokens rate data version 2. Only callable by Auths.
    /// @param tokensRateData_   array of RateDataV2Params with rate data to set for each token
    function updateRateDataV2s(
        AdminModuleStructs.RateDataV2Params[] calldata tokensRateData_
    ) external;

    /// @notice updates token configs: fee charge on borrowers interest & storage update utilization threshold.
    ///         Only callable by Auths.
    /// @param tokenConfigs_ contains token address, fee & utilization threshold
    function updateTokenConfigs(
        AdminModuleStructs.TokenConfig[] calldata tokenConfigs_
    ) external;

    /// @notice updates user classes: 0 is for new protocols, 1 is for established protocols.
    ///         Only callable by Auths.
    /// @param userClasses_ struct array of uint256 value to assign for each user address
    function updateUserClasses(
        AdminModuleStructs.AddressUint256[] calldata userClasses_
    ) external;

    /// @notice sets user supply configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userSupplyConfigs_ struct array containing user supply config, see `UserSupplyConfig` struct for more info
    function updateUserSupplyConfigs(
        AdminModuleStructs.UserSupplyConfig[] memory userSupplyConfigs_
    ) external;

    /// @notice setting user borrow configs per token basis. Eg: with interest or interest-free and automated limits.
    ///         Only callable by Auths.
    /// @param userBorrowConfigs_ struct array containing user borrow config, see `UserBorrowConfig` struct for more info
    function updateUserBorrowConfigs(
        AdminModuleStructs.UserBorrowConfig[] memory userBorrowConfigs_
    ) external;

    /// @notice pause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to pause operations for
    /// @param supplyTokens_  token addresses to pause withdrawals for
    /// @param borrowTokens_  token addresses to pause borrowings for
    function pauseUser(
        address user_,
        address[] calldata supplyTokens_,
        address[] calldata borrowTokens_
    ) external;

    /// @notice unpause operations for a particular user in class 0 (class 1 users can't be paused by guardians).
    /// Only callable by Guardians.
    /// @param user_          address of user to unpause operations for
    /// @param supplyTokens_  token addresses to unpause withdrawals for
    /// @param borrowTokens_  token addresses to unpause borrowings for
    function unpauseUser(
        address user_,
        address[] calldata supplyTokens_,
        address[] calldata borrowTokens_
    ) external;

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
    )
        external
        returns (
            uint256[] memory supplyExchangePrices_,
            uint256[] memory borrowExchangePrices_
        );
}

interface IFluidVaultT1Factory {
    /// @notice                         Deploys a new vault using the specified deployment logic `vaultDeploymentLogic_` and data `vaultDeploymentData_`.
    ///                                 Only accounts with deployer access or the owner can deploy a new vault.
    /// @param vaultDeploymentLogic_    The address of the vault deployment logic contract.
    /// @param vaultDeploymentData_     The data to be used for vault deployment.
    /// @return vault_                  Returns the address of the newly deployed vault.
    function deployVault(
        address vaultDeploymentLogic_,
        bytes calldata vaultDeploymentData_
    ) external returns (address vault_);

    /// @notice                         Sets an address as allowed vault deployment logic (`deploymentLogic_`) contract or not.
    ///                                 This function can only be called by the owner.
    /// @param deploymentLogic_         The address of the vault deployment logic contract to be set.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy new type of vault.
    function setVaultDeploymentLogic(
        address deploymentLogic_,
        bool allowed_
    ) external;
}

contract PayloadIGP25 {
    uint256 public constant PROPOSAL_ID = 25;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    address public constant PROPOSER_AVO_MULTISIG =
        0x059A94A72951c0ae1cc1CE3BF0dB52421bbE8210;

    address public constant PROPOSER_AVO_MULTISIG_2 =
        0x9efdE135CA4832AbF0408c44c6f5f370eB0f35e8;

    IGovernorBravo public constant GOVERNOR =
        IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public immutable TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    IFluidLiquidityAdmin public constant LIQUIDITY =
        IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);
    IFluidVaultT1Factory public constant VAULT_T1_FACTORY =
        IFluidVaultT1Factory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);

    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    constructor() {
        ADDRESS_THIS = address(this);
    }

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG_2,
            "msg.sender-not-allowed"
        );

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

        // Action 1: Update UserModule on Liquidity infiniteProxy.
        action1();

        // Action 2: Update AdminModule on Liquidity infiniteProxy.
        action2();

        // Action 3: Update dummyImplementation of Liquidity infiniteProxy.
        action3();

        // Action 4: Set max utilization to 85% for wstETH.
        action4();

        // Action 5: Remove max borrow handler for wstETH and add new buffer rate handler.
        action5();

        // Action 6: Update vault deployment logic on vaultT1 factory.
        action6();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update UserModule on Liquidity infiniteProxy.
    function action1() internal {
        address oldImplementation_ = 0x4Fc6D37FE897D6a7FfF0093D3B8418194ce1B1Bb;
        address newImplementation_ = 0xb290b44D34C4a44E233af73998C543832c418120;

        bytes4[] memory sigs_ = IProxy(address(LIQUIDITY))
            .getImplementationSigs(oldImplementation_);

        IProxy(address(LIQUIDITY)).removeImplementation(oldImplementation_);

        IProxy(address(LIQUIDITY)).addImplementation(newImplementation_, sigs_);
    }

    /// @notice Action 2: Update AdminModule on Liquidity infiniteProxy.
    function action2() internal {
        address oldImplementation_ = 0xF191F36385FFeefda54fB564cE374AAA86E2D08b;
        address newImplementation_ = 0xBDF3e6A0c721117B69150D00D9Fb27873023E4Df;

        bytes4[] memory sigs_ = IProxy(address(LIQUIDITY))
            .getImplementationSigs(oldImplementation_);

        for (uint i = 0; i < sigs_.length; i++) {
            if (sigs_[i] == 0x38b7e8e7) sigs_[i] = 0x7f7b6002;
        }

        IProxy(address(LIQUIDITY)).removeImplementation(oldImplementation_);

        IProxy(address(LIQUIDITY)).addImplementation(newImplementation_, sigs_);
    }

    /// @notice Action 3: Update dummyImplementation of Liquidity infiniteProxy.
    function action3() internal {
        IProxy(address(LIQUIDITY)).setDummyImplementation(
            0x102a42aa1F6BEA5c9eC200B95AFbf928ae4b855b
        );
    }

    /// @notice Action 4: Set max utilization to 85% for wstETH.
    function action4() internal {
        AdminModuleStructs.TokenConfig[]
            memory tokenConfigs_ = new AdminModuleStructs.TokenConfig[](1);

        tokenConfigs_[0] = AdminModuleStructs.TokenConfig({
            token: wstETH_ADDRESS,
            fee: 10 * 1e2, // 10%
            threshold: 0.3 * 1e2, // 0.3%
            maxUtilization: 85 * 1e2 // 85%
        });

        LIQUIDITY.updateTokenConfigs(tokenConfigs_);

        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

        configs_[0] = AdminModuleStructs.UserBorrowConfig({
            user: 0x40D9b8417E6E1DcD358f04E3328bCEd061018A82, // weETH / wstETH vault,
            token: wstETH_ADDRESS, // wstETH 
            mode: 1, // same as before: with interest
            expandPercent: 25 * 1e2, // same as before. 25%
            expandDuration: 12 hours, // same as before. 12h
            baseDebtCeiling: 4000 * 1e18, // same as before. 4000 wstETH
            maxDebtCeiling: 85_000 * 1e18 // updated as max cap is now handled w.r.t. to utilization 85% automatically. ~400M USD worth of wsteth, considering that this is set in raw with a borrow exchange price of ~1.043
        });

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 5: Remove max borrow handler for wstETH and add new buffer rate handler
    function action5() internal {
        AdminModuleStructs.AddressBool[]
            memory configs_ = new AdminModuleStructs.AddressBool[](2);

        // Remove max borrow handler for wstETH.
        {
            configs_[0] = AdminModuleStructs.AddressBool({
                addr: 0x383683D4414Fc27CC9669b7Cc6c7067716814b6a,
                value: false
            });
        }

        // Add new buffer rate handler
        {
            configs_[1] = AdminModuleStructs.AddressBool({
                addr: 0xDF10FE6163c1bfB99d7179e1bFC2e0Bb6128704f,
                value: true
            });
        }

        LIQUIDITY.updateAuths(configs_);
    }

    /// @notice Action 6: Update vault deployment logic on vaultT1 factory.
    function action6() internal {
        address oldImplementation_ = 0x15f6F562Ae136240AB9F4905cb50aCA54bCbEb5F;
        address newImplementation_ = 0x2Cc710218F2e3a82CcC77Cc4B3B93Ee6Ba9451CD;

        VAULT_T1_FACTORY.setVaultDeploymentLogic(oldImplementation_, false);

        VAULT_T1_FACTORY.setVaultDeploymentLogic(newImplementation_, true);
    }
}
