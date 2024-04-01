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

interface IFluidLendingFactory {
    /// @notice creates token for `asset_` for a lending protocol with interest. Only callable by deployers.
    /// @param  asset_              address of the asset
    /// @param  fTokenType_         type of fToken:
    /// - if it's the native token, it should use `NativeUnderlying`
    /// - otherwise it should use `fToken`
    /// - could be more types available, check `fTokenTypes()`
    /// @param  isNativeUnderlying_ flag to signal fToken type that uses native underlying at Liquidity
    /// @return token_              address of the created token
    function createToken(
        address asset_,
        string calldata fTokenType_,
        bool isNativeUnderlying_
    ) external returns (address token_);
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

interface IFluidLending {
    /// @notice Updates the rebalancer address (ReserveContract). Only callable by LendingFactory auths.
    function updateRebalancer(address rebalancer_) external;
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

contract PayloadIGP16 {
    uint256 public constant PROPOSAL_ID = 16;

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
     IFluidLendingFactory public constant LENDING_FACTORY =
        IFluidLendingFactory(0x54B91A0D94cb471F37f949c60F7Fa7935b551D03);

    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address public constant VAULT_ETH_USDC = address(0xeAbBfca72F8a8bf14C4ac59e69ECB2eB69F0811C);
    address public constant VAULT_ETH_USDT = address(0xbEC491FeF7B4f666b270F9D5E5C3f443cBf20991);
    address public constant VAULT_wstETH_USDC = address(0x51197586F6A9e2571868b6ffaef308f3bdfEd3aE);
    address public constant VAULT_wstETH_USDT = address(0x1c2bB46f36561bc4F05A94BD50916496aa501078);
    address public constant VAULT_weETH_wstETH = address(0x40D9b8417E6E1DcD358f04E3328bCEd061018A82);

    

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

        // Action 1: Update wstETH market rate curve and set fee as 10%
        action1();

        // Action 2: Update ETH market rate curve and set fee as 0%.
        action2();

        // Action 3: Add config handler on liquidity layer for weETH/wstETH vault to make borrow limit dynamic.
        action3();

        // Action 4: Update supply rate magnifier wstETH/USDC and wstETH/USDT vault.
        action4();

        // Action 5: Pauses ETH Rewards on ETH/USDC and ETH/USDT vaults.
        action5();

        // Action 6: Enabling wstETH token on lending protocol.
        action6();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update wstETH market rate curve and set fee as 10%
    function action1() internal {
        {
            AdminModuleStructs.RateDataV2Params[]
                memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

            params_[0] = AdminModuleStructs.RateDataV2Params({
                token: wstETH_ADDRESS, // wstETH
                kink1: 70 * 1e2, // 70%
                kink2: 90 * 1e2, // 90%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 20 * 1e2, // 20%
                rateAtUtilizationKink2: 40 * 1e2, // 40%
                rateAtUtilizationMax: 150 * 1e2 // 150%
            });

            LIQUIDITY.updateRateDataV2s(params_);
        }

        {
            AdminModuleStructs.TokenConfig[]
                memory params_ = new AdminModuleStructs.TokenConfig[](1);

            params_[0] = AdminModuleStructs.TokenConfig({
                token: wstETH_ADDRESS, // wstETH
                threshold: 0.3 * 1e2, // 0.3
                fee: 10 * 1e2 // 10%
            });

            LIQUIDITY.updateTokenConfigs(params_);
        }
    }

    /// @notice Action 2: Update ETH market rate curve and set fee as 0%.
    function action2() internal {
        {
            AdminModuleStructs.RateDataV2Params[]
                memory params_ = new AdminModuleStructs.RateDataV2Params[](1);

            params_[0] = AdminModuleStructs.RateDataV2Params({
                token: ETH_ADDRESS, // ETH
                kink1: 70 * 1e2, // 70%
                kink2: 90 * 1e2, // 90%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink1: 15 * 1e2, // 15%
                rateAtUtilizationKink2: 25 * 1e2, // 25%
                rateAtUtilizationMax: 150 * 1e2 // 150%
            });

            LIQUIDITY.updateRateDataV2s(params_);
        }


         {
            AdminModuleStructs.TokenConfig[]
                memory params_ = new AdminModuleStructs.TokenConfig[](1);

            params_[0] = AdminModuleStructs.TokenConfig({
                token: ETH_ADDRESS, // wstETH
                threshold: 0.3 * 1e2, // 0.3
                fee: 0 * 1e2 // 0%
            });

            LIQUIDITY.updateTokenConfigs(params_);
        }
    }

    /// @notice Action 3: Add config handler on liquidity layer for weETH/wstETH vault to make borrow limit dynamic
    function action3() internal {
        address VAULT_weETH_wstETH_CONFIG_HANDLER = address(0); // TODO

        AdminModuleStructs.AddressBool[]
            memory configs_ = new AdminModuleStructs.AddressBool[](1);

        configs_[0] = AdminModuleStructs.AddressBool({
            addr: address(VAULT_weETH_wstETH_CONFIG_HANDLER),
            value: true
        });

        LIQUIDITY.updateAuths(configs_);
    }

    /// @notice Action 4: Update supply rate magnifier wstETH/USDC and wstETH/USDT vault.
    function action4() internal {
        IFluidVaultT1(VAULT_wstETH_USDC).updateSupplyRateMagnifier(80 * 1e2); // 0.8x supplyRateMagnifier
        IFluidVaultT1(VAULT_wstETH_USDT).updateSupplyRateMagnifier(80 * 1e2); // 0.8x supplyRateMagnifier
    }


    /// @notice Action 5: Pauses ETH Rewards on ETH/USDC and ETH/USDT vaults.
    function action5() internal {
        IFluidVaultT1(VAULT_ETH_USDC).updateSupplyRateMagnifier(100 * 1e2); // 1x supplyRateMagnifier
        VAULT_T1_FACTORY.setVaultAuth(VAULT_ETH_USDC, 0x58Dc7894a7B1B9D065CE2e94a73f62686B439A2A, false); // Removing Rewards contracts as auth

        IFluidVaultT1(VAULT_ETH_USDT).updateSupplyRateMagnifier(100 * 1e2); // 1x supplyRateMagnifier
        VAULT_T1_FACTORY.setVaultAuth(VAULT_ETH_USDC, 0xB36Db4dfF978D2d552a5149E2fd0FBefA2a32809, false); // Removing Rewards contracts as auth

    }

    /// @notice Action 6: Deploy and enable wstETH token on lending protocol.
    function action6() internal {
        // deploy fToken for wstETH
        address F_WSTETH = LENDING_FACTORY.createToken(wstETH_ADDRESS, "fToken", false);

        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(F_WSTETH),
                token: wstETH_ADDRESS,
                mode: 1,
                expandPercent: 25 * 1e2, // 25%
                expandDuration: 12 hours,
                baseWithdrawalLimit: 4000 * 1e18 // 4000 wstETH
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // set rebalancer at fToken to reserve contract proxy
        IFluidLending(F_WSTETH).updateRebalancer(0x264786EF916af64a1DB19F513F24a3681734ce92);
    }
}