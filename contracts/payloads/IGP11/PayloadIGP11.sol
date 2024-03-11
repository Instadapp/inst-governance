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

interface IFluidVaultT1Factory {
    function deployVault(address vaultDeploymentLogic_, bytes calldata vaultDeploymentData_) external returns (address vault_);
}

interface IFluidVaultT1DeploymentLogic {
    function vaultT1(
        address supplyToken_,
        address borrowToken_
    ) external;
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
    function updateSupplyRateMagnifier(uint supplyRateMagnifier_) public
}

contract PayloadIGP11 {
    uint256 public constant PROPOSAL_ID = 11;

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
    IFluidVaultT1Factory public constant VAULT_T1_FACTORY = IFluidVaultT1Factory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);
    IFluidVaultT1DeploymentLogic public constant VAULT_T1_DEPLOYMENT_LOGIC = IFluidVaultT1DeploymentLogic(0x15f6F562Ae136240AB9F4905cb50aCA54bCbEb5F);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant weETH_ADDRESS = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant wstETH_ADDRESS = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

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

        // Action 1: Set market rates for weETH on Liquidity.
        action1();

        // Action 2: Set token config for weETH on Liquidity.
        action2();

        //  Action 3: Deploy weETH/wstETH vault.
        address vault_ = action3();

        // Action 4: Set user supply config for the vault on Liquidity Layer.
        action4(vault_);

        // Action 5: Set user borrow config for the vault on Liquidity Layer.
        action5(vault_);

        // Action 6: Update core settings on weETH/wstETH vault.
        action6(vault_);

        // Action 7: Update oracle on weETH/wstETH vault.
        action7(vault_);

        // Action 8: Update rebalancer on weETH/wstETH vault.
        action8(vault_);

        // Action 9: Update supply magnifier on wstETH/ETH, wstETH/USDC & wstETH/USDT vault 
        action9(vault_);

        // Action 10: Update market rates for wstETH on Liquidity.
        action10();

        // Action 11: Update token config for wstETH on Liquidity.
        action11();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Set market rates for weETH on Liquidity.
    function action1() internal {
       AdminModuleStructs.RateDataV2Params[] memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

       params_[0] = AdminModuleStructs.RateDataV2Params({
            token: weETH_ADDRESS, // weETH
            kink1: 50 * 1e2, // 50%
            kink2: 80 * 1e2, // 80%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 20 * 1e2, // 20%
            rateAtUtilizationKink2: 40 * 1e2, // 40%
            rateAtUtilizationMax: 100 * 1e2 // 100%
       });

       LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 2: Set token config for weETH on Liquidity.
    function action2() internal {
       AdminModuleStructs.TokenConfig[] memory params_ = new AdminModuleStructs.TokenConfig[](1);

       params_[0] = AdminModuleStructs.TokenConfig({
            token: weETH_ADDRESS, // weETH
            threshold: 0.3 * 1e2, // 0.3
            fee: 10 * 1e2 // 10%
       });

       LIQUIDITY.updateTokenConfigs(params_);
    }

    /// @notice Action 3: Deploy weETH/wstETH vault.
    function action3() internal returns (address vault_){
        vault_ = VAULT_T1_FACTORY.deployVault(
            address(VAULT_T1_DEPLOYMENT_LOGIC),
            abi.encodeWithSelector(
                IFluidVaultT1DeploymentLogic.vaultT1.selector,
                weETH_ADDRESS, // weETH,
                wstETH_ADDRESS // wstETH
            )
        );
    }

    /// @notice Action 4: Set user supply config for the vault on Liquidity Layer.
    function action4(address vault_) internal {
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);
       
        configs_[0] = AdminModuleStructs.UserSupplyConfig({
            user: address(vault_),
            token: weETH_ADDRESS,
            mode: 1,
            expandPercent: 25 * 1e2,
            expandDuration: 12 hours,
            baseWithdrawalLimit: 4000 * 1e18
        });

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }

    /// @notice Action 5: Set user borrow config for the vault on Liquidity Layer.
    function action5(address vault_) internal {
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);
       
        configs_[0] = AdminModuleStructs.UserBorrowConfig({
            user: address(vault_),
            token: wstETH_ADDRESS,
            mode: 1,
            expandPercent: 25 * 1e2,
            expandDuration: 12 hours,
            baseDebtCeiling: 4000 * 1e18,
            maxDebtCeiling: 10000 * 1e18
        });

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 6: Update core settings on weETH/wstETH vault.
    function action6(address vault_) internal {
        IFluidVaultT1(vault_).updateCoreSettings(
            100  * 1e2, // 1x     supplyRateMagnifier
            100  * 1e2, // 1x     borrowRateMagnifier
            90.5 * 1e2, // 90.5%  collateralFactor
            93   * 1e2, // 93%    liquidationThreshold
            95   * 1e2, // 95%    liquidationMaxLimit
            5    * 1e2, // 5%     withdrawGap
            1    * 1e2, // 2%     liquidationPenalty
            0           // 0%     borrowFee
        );
    }

    /// @notice Action 7: Update oracle on weETH/wstETH vault.
    function action7(address vault_) internal {
        IFluidVaultT1(vault_).updateOracle(0x9eC721a12b6005aF8c6E8CFa9c86B5f12ff473E4);
    }

    /// @notice Action 8: Update rebalancer on weETH/wstETH vault.
    function action8(address vault_) internal {
        IFluidVaultT1(vault_).updateRebalancer(0x264786EF916af64a1DB19F513F24a3681734ce92);
    }

    /// @notice Action 9: UpdateSupplyMagnifier on wstETH/ETH, wstETH/USDC & wstETH/USDT vault 
    function action9() internal {
        address[] memory wstETHVaults_ = [
            0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91, // wstETH/ETH
            0x51197586F6A9e2571868b6ffaef308f3bdfEd3aE, // wstETH/USDC
            0x1c2bB46f36561bc4F05A94BD50916496aa501078, // wstETH/USDT
        ]

        for (uint256 i = 0; i < wstETHVaults_; i++) {
            IFluidVaultT1(wstETHVaults_[i]).updateSupplyRateMagnifier(1 * 1e4); // 1x
        }
    }

    /// @notice Action 10: Update market rates for wstETH on Liquidity.
    function action10() internal {
        AdminModuleStructs.RateDataV2Params[] memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

       params_[0] = AdminModuleStructs.RateDataV2Params({
            token: wstETH_ADDRESS, // wstETH
            kink1: 50 * 1e2, // 50%
            kink2: 80 * 1e2, // 80%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 15 * 1e2, // 15%
            rateAtUtilizationKink2: 30 * 1e2, // 30%
            rateAtUtilizationMax: 150 * 1e2 // 150%
       });

       LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 11: Update token config for wstETH on Liquidity.
    function action11() internal {
        AdminModuleStructs.TokenConfig[] memory params_ = new AdminModuleStructs.TokenConfig[](1);

        params_[0] = AdminModuleStructs.TokenConfig({
                token: wstETH_ADDRESS, // wstETH
                threshold: 0.3 * 1e2, // 0.3
                fee: 70 * 1e2 // 70%
        });

       LIQUIDITY.updateTokenConfigs(params_);
    }
}
