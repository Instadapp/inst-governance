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
    function deployVault(
        address vaultDeploymentLogic_,
        bytes calldata vaultDeploymentData_
    ) external returns (address vault_);

    function setVaultAuth(
        address vault_,
        address vaultAuth_,
        bool allowed_
    ) external;
}

interface IFluidVaultT1DeploymentLogic {
    function vaultT1(address supplyToken_, address borrowToken_) external;
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

interface IFTokenAdmin {
    /// @notice updates the rewards rate model contract.
    ///         Only callable by LendingFactory auths.
    /// @param rewardsRateModel_  the new rewards rate model contract address.
    ///                           can be set to address(0) to set no rewards (to save gas)
    function updateRewards(address rewardsRateModel_) external;

    /// @notice Balances out the difference between fToken supply at Liquidity vs totalAssets().
    ///         Deposits underlying from rebalancer address into Liquidity but doesn't mint any shares
    ///         -> thus making deposit available as rewards.
    ///         Only callable by rebalancer.
    /// @return assets_ amount deposited to Liquidity
    function rebalance() external payable returns (uint256 assets_);

    /// @notice gets the liquidity exchange price of the underlying asset, calculates the updated exchange price (with reward rates)
    ///         and writes those values to storage.
    ///         Callable by anyone.
    /// @return tokenExchangePrice_ exchange price of fToken share to underlying asset
    /// @return liquidityExchangePrice_ exchange price at Liquidity for the underlying asset
    function updateRates()
        external
        returns (uint256 tokenExchangePrice_, uint256 liquidityExchangePrice_);

    /// @notice sends any potentially stuck funds to Liquidity contract. Only callable by LendingFactory auths.
    function rescueFunds(address token_) external;

    /// @notice Updates the rebalancer address (ReserveContract). Only callable by LendingFactory auths.
    function updateRebalancer(address rebalancer_) external;
}

contract PayloadIGP15 {
    uint256 public constant PROPOSAL_ID = 15;

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

    IFluidLiquidityAdmin public constant LIQUIDITY =
        IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);
    IFluidVaultT1Factory public constant VAULT_T1_FACTORY =
        IFluidVaultT1Factory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);
    IFluidVaultT1DeploymentLogic public constant VAULT_T1_DEPLOYMENT_LOGIC =
        IFluidVaultT1DeploymentLogic(
            0x15f6F562Ae136240AB9F4905cb50aCA54bCbEb5F
        );

    address public constant F_USDT = 0x5C20B550819128074FD538Edf79791733ccEdd18;
    address public constant F_USDC = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33;

    address public constant sUSDe_ADDRESS =
        0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor() {
        ADDRESS_THIS = address(this);
    }

    function propose(string memory description) external {
        require(
            msg.sender == PROPOSER ||
                msg.sender == TEAM_MULTISIG ||
                address(this) == PROPOSER_AVO_MULTISIG,
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

        // Action 1: Set market rates for sUSDe on Liquidity.
        action1();

        // Action 2: Set token config for sUSDe on Liquidity.
        action2();

        // Action 3: Deploy sUSDe/USDC vault and set related configs.
        action3();

        // Action 4: Deploy sUSDe/USDT vault and set related configs.
        action4();

        // Action 5: Update market rates for USDC.
        action5();

        // Action 6: Update market rates for USDT.
        action6();

        // Action 7: Update reward rates for USDC.
        action7();

        // Action 8: Update reward rates for USDT.
        action8();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Set market rates for sUSDe on Liquidity.
    function action1() internal {
        AdminModuleStructs.RateDataV2Params[]
            memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

        params_[0] = AdminModuleStructs.RateDataV2Params({
            token: sUSDe_ADDRESS, // sUSDe
            kink1: 50 * 1e2, // 50%
            kink2: 80 * 1e2, // 80%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 20 * 1e2, // 20%
            rateAtUtilizationKink2: 40 * 1e2, // 40%
            rateAtUtilizationMax: 100 * 1e2 // 100%
        });

        LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 2: Set token config for sUSDe on Liquidity.
    function action2() internal {
        AdminModuleStructs.TokenConfig[]
            memory params_ = new AdminModuleStructs.TokenConfig[](1);

        params_[0] = AdminModuleStructs.TokenConfig({
            token: sUSDe_ADDRESS, // sUSDe
            threshold: 0.3 * 1e2, // 0.3
            fee: 10 * 1e2 // 10%
        });

        LIQUIDITY.updateTokenConfigs(params_);
    }

    /// @notice Action 3: Deploy sUSDe/USDC vault and set related configs.
    function action3() internal {
        deploy_sUSDe_USDC_VAULT();
    }

    /// @notice Action 4: Deploy sUSDe/USDT vault and set related configs.
    function action4() internal {
        deploy_sUSDe_USDT_VAULT();
    }

    /// @notice Action 5: Update market rates for USDC.
    function action5() internal {
        AdminModuleStructs.RateDataV2Params[]
            memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

        params_[0] = AdminModuleStructs.RateDataV2Params({
            token: USDC_ADDRESS, // USDC
            kink1: 80 * 1e2, // 80%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 10 * 1e2, // 10%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 25 * 1e2 // 25%
        });

        LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 6: Update market rates for USDT.
    function action6() internal {
        AdminModuleStructs.RateDataV2Params[]
            memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

        params_[0] = AdminModuleStructs.RateDataV2Params({
            token: USDT_ADDRESS, // USDT
            kink1: 80 * 1e2, // 80%
            kink2: 93 * 1e2, // 93%
            rateAtUtilizationZero: 0, // 0%
            rateAtUtilizationKink1: 10 * 1e2, // 10%
            rateAtUtilizationKink2: 15 * 1e2, // 15%
            rateAtUtilizationMax: 25 * 1e2 // 25%
        });

        LIQUIDITY.updateRateDataV2s(params_);
    }

    /// @notice Action 7: Update rewards for fUSDC.
    function action7() internal {
        IFTokenAdmin(F_USDC).updateRewards(
            0x6CC89782495A2162b2A4f5b206E2A06Dc8675090
        );
    }

    /// @notice Action 8: Update rewards for fUSDT.
    function action8() internal {
        IFTokenAdmin(F_USDT).updateRewards(
            0x6CC89782495A2162b2A4f5b206E2A06Dc8675090
        );
    }

    /***********************************|
    |     Vault Deployment Helper       |
    |__________________________________*/
    function deploy_sUSDe_USDC_VAULT() internal {
        // Deploy sUSDe/USDC vault.
        address vault_ = VAULT_T1_FACTORY.deployVault(
            address(VAULT_T1_DEPLOYMENT_LOGIC),
            abi.encodeWithSelector(
                IFluidVaultT1DeploymentLogic.vaultT1.selector,
                sUSDe_ADDRESS, // sUSDe,
                USDC_ADDRESS // USDC
            )
        );

        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(vault_),
                token: sUSDe_ADDRESS,
                mode: 1,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours,
                baseWithdrawalLimit: 7_500_000 * 1e18 // 7.5M
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = AdminModuleStructs.UserBorrowConfig({
                user: address(vault_),
                token: USDC_ADDRESS,
                mode: 1,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours,
                baseDebtCeiling: 7_500_000 * 1e6, // 7.5M
                maxDebtCeiling: 20_000_000 * 1e6  // 20M
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }

        // Update core settings on sUSDe/USDC vault.
        {
            IFluidVaultT1(vault_).updateCoreSettings(
                100 * 1e2, // 1x     supplyRateMagnifier
                100 * 1e2, // 1x     borrowRateMagnifier
                88 * 1e2, // 88%     collateralFactor
                90 * 1e2, // 90%    liquidationThreshold
                95 * 1e2, // 95%    liquidationMaxLimit
                5 * 1e2, // 5%     withdrawGap
                2 * 1e2, // 2%     liquidationPenalty
                0 // 0%     borrowFee
            );
        }

        // Update oracle on sUSDe/USDC vault.
        {
            IFluidVaultT1(vault_).updateOracle(
                0x7779EC4694752A118580cc8ad28B9A11F7e3bB12
            );
        }

        // Update rebalancer on sUSDe/USDC vault.
        {
            IFluidVaultT1(vault_).updateRebalancer(
                0x264786EF916af64a1DB19F513F24a3681734ce92
            );
        }

        // Set Config hander as auth on vault factory for sUSDe/USDC vault.
        {
            VAULT_T1_FACTORY.setVaultAuth(
                vault_,
                0x36639DAd77eC858574aaF07a68bBa62b7db19FfA,
                true
            );
        }
    }

    function deploy_sUSDe_USDT_VAULT() internal {
        // Deploy sUSDe/USDT vault.
        address vault_ = VAULT_T1_FACTORY.deployVault(
            address(VAULT_T1_DEPLOYMENT_LOGIC),
            abi.encodeWithSelector(
                IFluidVaultT1DeploymentLogic.vaultT1.selector,
                sUSDe_ADDRESS, // sUSDe,
                USDT_ADDRESS // USDT
            )
        );

        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(vault_),
                token: sUSDe_ADDRESS,
                mode: 1,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours,
                baseWithdrawalLimit: 7_500_000 * 1e18 // 7.5M
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = AdminModuleStructs.UserBorrowConfig({
                user: address(vault_),
                token: USDT_ADDRESS,
                mode: 1,
                expandPercent: 20 * 1e2, // 20%
                expandDuration: 12 hours,
                baseDebtCeiling: 7_500_000 * 1e6, // 7.5M
                maxDebtCeiling: 20_000_000 * 1e6  // 20M
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }

        // Update core settings on sUSDe/USDT vault.
        {
            IFluidVaultT1(vault_).updateCoreSettings(
                100 * 1e2, // 1x     supplyRateMagnifier
                100 * 1e2, // 1x     borrowRateMagnifier
                88 * 1e2, // 88%     collateralFactor
                90 * 1e2, // 90%    liquidationThreshold
                95 * 1e2, // 95%    liquidationMaxLimit
                5 * 1e2, // 5%     withdrawGap
                2 * 1e2, // 2%     liquidationPenalty
                0 // 0%     borrowFee
            );
        }

        // Update oracle on sUSDe/USDT vault.
        {
            IFluidVaultT1(vault_).updateOracle(
                0x7779EC4694752A118580cc8ad28B9A11F7e3bB12
            );
        }

        // Update rebalancer on sUSDe/USDT vault.
        {
            IFluidVaultT1(vault_).updateRebalancer(
                0x264786EF916af64a1DB19F513F24a3681734ce92
            );
        }

        // Set Config hander as auth on vault factory for sUSDe/USDT vault.
        {
            VAULT_T1_FACTORY.setVaultAuth(
                vault_,
                0xafE3974f4916140a093F1de7Fc064A3Da220DD41,
                true
            );
        }
    }
}
