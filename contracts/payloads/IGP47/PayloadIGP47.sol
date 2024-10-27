pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";

interface IGovernorBravo {
    function _acceptAdmin() external;

    function _setVotingDelay(uint256 newVotingDelay) external;

    function _setVotingPeriod(uint256 newVotingPeriod) external;

    function _acceptAdminOnTimelock() external;

    function _setImplementation(address implementation_) external;

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function admin() external view returns (address);

    function pendingAdmin() external view returns (address);

    function timelock() external view returns (address);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);
}

interface ITimelock {
    function acceptAdmin() external;

    function setDelay(uint256 delay_) external;

    function setPendingAdmin(address pendingAdmin_) external;

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external returns (bytes32);

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
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

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
}

interface FluidVaultFactory {
    /// @notice                         Sets an address as allowed vault deployment logic (`deploymentLogic_`) contract or not.
    ///                                 This function can only be called by the owner.
    /// @param deploymentLogic_         The address of the vault deployment logic contract to be set.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy new type of vault.
    function setVaultDeploymentLogic(
        address deploymentLogic_,
        bool allowed_
    ) external;

    /// @notice                         Sets an address (`vaultAuth_`) as allowed vault authorization or not for a specific vault (`vault_`).
    ///                                 This function can only be called by the owner.
    /// @param vault_                   The address of the vault for which the authorization is being set.
    /// @param vaultAuth_               The address to be set as vault authorization.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to update the specific vault config.
    function setVaultAuth(
        address vault_,
        address vaultAuth_,
        bool allowed_
    ) external;

    /// @notice                         Computes the address of a vault based on its given ID (`vaultId_`).
    /// @param vaultId_                 The ID of the vault.
    /// @return vault_                  Returns the computed address of the vault.
    function getVaultAddress(
        uint256 vaultId_
    ) external view returns (address vault_);
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

    /// @notice updates the borrow rate magnifier to `borrowRateMagnifier_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateBorrowRateMagnifier(uint borrowRateMagnifier_) external;

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

interface IFluidReserveContract {
    function isRebalancer(address user) external returns (bool);

    function rebalanceFToken(address protocol_) external;

    function rebalanceVault(address protocol_) external;

    function transferFunds(address token_) external;

    function getProtocolTokens(address protocol_) external;

    function updateAuth(address auth_, bool isAuth_) external;

    function updateRebalancer(address rebalancer_, bool isRebalancer_) external;

    function approve(
        address[] memory protocols_,
        address[] memory tokens_,
        uint256[] memory amounts_
    ) external;

    function revoke(
        address[] memory protocols_,
        address[] memory tokens_
    ) external;
}


contract PayloadIGP47 {
    uint256 public constant PROPOSAL_ID = 47;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;
    address public constant PROPOSER_AVO_MULTISIG =
        0x059a94a72451c0ae1Cc1cE4bf0Db52421Bbe8210;
    address public constant PROPOSER_AVO_MULTISIG_2 =
        0x9efdE135CA4832AbF0408c44c6f5f370eB0f35e8;
    address public constant PROPOSER_AVO_MULTISIG_3 =
        0x5C43AAC965ff230AC1cF63e924D0153291D78BaD;

    IGovernorBravo public constant GOVERNOR =
        IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public constant TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    address public immutable ADDRESS_THIS;

    IFluidLiquidityAdmin public constant LIQUIDITY =
        IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);
    IFluidReserveContract public constant FLUID_RESERVE =
        IFluidReserveContract(0x264786EF916af64a1DB19F513F24a3681734ce92);

    FluidVaultFactory public constant VAULT_FACTORY =
        FluidVaultFactory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);

    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant sUSDe_ADDRESS =
        0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address internal constant sUSDs_ADDRESS =
        0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;

    address internal constant GHO_ADDRESS =
        0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

    address internal constant WBTC_ADDRESS =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant cbBTC_ADDRESS =
        0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    struct Dex {
        address dex;
        address tokenA;
        address tokenB;
        bool smartCollateral;
        bool smartDebt;
        uint256 baseWithdrawalLimitInUSD;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    enum TYPE {
        TYPE_2,
        TYPE_3,
        TYPE_4
    }

    struct Vault {
        address vault;
        TYPE vaultType;
        address supplyToken;
        address borrowToken;
    }

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

        // Action 1: call executePayload on timelock contract to execute payload related to Fluid and Lite
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

        // Action 1: Set GHO token config and market rate curve on liquidity.
        action1();

        // Action 2: Set GHO based vaults limits.
        action2();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Set GHO token config and market rate curve on liquidity.
    function action1() internal {
        {
            AdminModuleStructs.RateDataV1Params[]
                memory params_ = new AdminModuleStructs.RateDataV1Params[](1);

            params_[0] = AdminModuleStructs.RateDataV1Params({
                token: GHO_ADDRESS, // GHO
                kink: 93 * 1e2, // 93%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink: 7.5 * 1e2, // 7.5%
                rateAtUtilizationMax: 100 * 1e2 // 100%
            });

            LIQUIDITY.updateRateDataV1s(params_);
        }
    }

    /// @notice Action 2: Set GHO based vaults limits.
    function action2() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 7_500_000, // $7.5M
            supplyBaseLimit: 0,
            borrowToken: GHO_ADDRESS,
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowBaseLimit: 0,
            borrowMaxLimitInUSD: 20_000_000, // $20M
            borrowMaxLimit: 0,
            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 0, 
            liquidationThreshold: 0,
            liquidationMaxLimit: 0,
            withdrawGap: 0,
            liquidationPenalty: 0,
            borrowFee: 0, // 0%
            oracle: address(0)
        });

        // Config ETH/GHO vault.
        {
            vaultConfig.vaultId = 54;
            vaultConfig.supplyToken = ETH_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 90 * 1e2; // 90%
            vaultConfig.liquidationMaxLimit = 93 * 1e2; // 95%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 2.5 * 1e2; // 5%

            vaultConfig.oracle = address(
                0x39f6447ca8Ac3c6aa841B4C0D1fFb5D4DDb0FdE7
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config wstETH/GHO vault.
        {
            vaultConfig.vaultId = 55;
            vaultConfig.supplyToken = wstETH_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 82 * 1e2; // 82%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(
                0xbEeCb9e594D008194c438f9e7234e17926c5070f
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config sUSDe/GHO vault.
        {
            vaultConfig.vaultId = 56;
            vaultConfig.supplyToken = sUSDe_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 88 * 1e2; // 88%
            vaultConfig.liquidationThreshold = 90 * 1e2; // 90%
            vaultConfig.liquidationMaxLimit = 95 * 1e2; // 95%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 2 * 1e2; // 2%

            vaultConfig.oracle = address(
                0x887d0aFb83949dd2d379e55E122c3c234D68F8BF
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config weETH/GHO vault.
        {
            vaultConfig.vaultId = 57;
            vaultConfig.supplyToken = weETH_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 77 * 1e2; // 77%
            vaultConfig.liquidationThreshold = 82 * 1e2; // 82%
            vaultConfig.liquidationMaxLimit = 90 * 1e2; // 90%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(
                0x8d675657712C3621Fb5Ea57E6fE83F6799224C98
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config sUSDs/GHO vault.
        {
            vaultConfig.vaultId = 58;
            vaultConfig.supplyToken = sUSDs_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 90 * 1e2; // 90%
            vaultConfig.liquidationThreshold = 92 * 1e2; // 92%
            vaultConfig.liquidationMaxLimit = 95 * 1e2; // 95%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 2 * 1e2; // 2%

            vaultConfig.oracle = address(
                0xCac98B078aC63432d77dfd4DCFDB39D3033C9D11
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config wBTC/GHO vault.
        {
            vaultConfig.vaultId = 59;
            vaultConfig.supplyToken = WBTC_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(
                0x687351DF42715Dd0F2ebfdeAc2C73D374E66bD90
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config cbBTC/GHO vault.
        {
            vaultConfig.vaultId = 60;
            vaultConfig.supplyToken = cbBTC_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(
                0x8Ae43Ebc63d0C49C2478066bFf097Dc3FE05B5ac
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }
    }

    /**
     * |
     * |     Proposal Payload Helpers      |
     * |__________________________________
     */
    function getVaultAddress(uint256 vaultId_) public view returns (address) {
        return VAULT_FACTORY.getVaultAddress(vaultId_);
    }

    struct VaultConfig {
        uint256 vaultId;
        address supplyToken;
        uint8 supplyMode;
        uint256 supplyExpandPercent;
        uint256 supplyExpandDuration;
        uint256 supplyBaseLimitInUSD;
        uint256 supplyBaseLimit;
        address borrowToken;
        uint8 borrowMode;
        uint256 borrowExpandPercent;
        uint256 borrowExpandDuration;
        uint256 borrowBaseLimitInUSD;
        uint256 borrowBaseLimit;
        uint256 borrowMaxLimitInUSD;
        uint256 borrowMaxLimit;
        uint256 supplyRateMagnifier;
        uint256 borrowRateMagnifier;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationMaxLimit;
        uint256 withdrawGap;
        uint256 liquidationPenalty;
        uint256 borrowFee;
        address oracle;
    }

    function configVault(
        VaultConfig memory vaultConfig
    ) internal returns (address vault_) {
        // Deploy vault.
        vault_ = VAULT_FACTORY.getVaultAddress(vaultConfig.vaultId);

        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(vault_),
                token: vaultConfig.supplyToken,
                mode: vaultConfig.supplyMode,
                expandPercent: vaultConfig.supplyExpandPercent,
                expandDuration: vaultConfig.supplyExpandDuration,
                baseWithdrawalLimit: getRawAmount(
                    vaultConfig.supplyToken,
                    vaultConfig.supplyBaseLimit,
                    vaultConfig.supplyBaseLimitInUSD,
                    true
                )
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = AdminModuleStructs.UserBorrowConfig({
                user: address(vault_),
                token: vaultConfig.borrowToken,
                mode: vaultConfig.borrowMode,
                expandPercent: vaultConfig.borrowExpandPercent,
                expandDuration: vaultConfig.borrowExpandDuration,
                baseDebtCeiling: getRawAmount(
                    vaultConfig.borrowToken,
                    vaultConfig.borrowBaseLimit,
                    vaultConfig.borrowBaseLimitInUSD,
                    false
                ),
                maxDebtCeiling: getRawAmount(
                    vaultConfig.borrowToken,
                    vaultConfig.borrowMaxLimit,
                    vaultConfig.borrowMaxLimitInUSD,
                    false
                )
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }

        // Update core settings on vault.
        {
            IFluidVaultT1(vault_).updateCoreSettings(
                vaultConfig.supplyRateMagnifier,
                vaultConfig.borrowRateMagnifier,
                vaultConfig.collateralFactor,
                vaultConfig.liquidationThreshold,
                vaultConfig.liquidationMaxLimit,
                vaultConfig.withdrawGap,
                vaultConfig.liquidationPenalty,
                vaultConfig.borrowFee
            );
        }

        // Update oracle on vault.
        {
            IFluidVaultT1(vault_).updateOracle(vaultConfig.oracle);
        }

        // Update rebalancer on vault.
        {
            IFluidVaultT1(vault_).updateRebalancer(address(FLUID_RESERVE));
        }
    }

    function getRawAmount(
        address token,
        uint256 amount,
        uint256 amountInUSD,
        bool isSupply
    ) public view returns (uint256) {
        if (amount > 0 && amountInUSD > 0) {
            revert("both usd and amount are not zero");
        }
        uint256 exchangePriceAndConfig_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                token
            )
        );

        (
            uint256 supplyExchangePrice,
            uint256 borrowExchangePrice
        ) = LiquidityCalcs.calcExchangePrices(exchangePriceAndConfig_);

        uint256 usdPrice = 0;
        uint256 decimals = 18;
        if (token == ETH_ADDRESS) {
            usdPrice = 2_500 * 1e2;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = 2_970 * 1e2;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = 2_650 * 1e2;
            decimals = 18;
        } else if (token == cbBTC_ADDRESS || token == WBTC_ADDRESS) {
            usdPrice = 67_750 * 1e2;
            decimals = 8;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = 1 * 1e2;
            decimals = 6;
        } else if (token == sUSDe_ADDRESS) {
            usdPrice = 1.1 * 1e2;
            decimals = 18;
        } else if (token == GHO_ADDRESS || token == sUSDs_ADDRESS) {
            usdPrice = 1 * 1e2;
            decimals = 18;
        } else {
            revert("not-found");
        }

        uint256 exchangePrice = isSupply
            ? supplyExchangePrice
            : borrowExchangePrice;

        if (amount > 0) {
            return (amount * 1e12) / exchangePrice;
        } else {
            return
                (amountInUSD * 1e12 * (10 ** decimals)) /
                ((usdPrice * exchangePrice) / 1e2);
        }
    }
}
