pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

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

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes32);

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        payable
        returns (bytes memory);

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
    function updateExchangePrices(address[] calldata tokens_)
        external
        returns (uint256[] memory supplyExchangePrices_, uint256[] memory borrowExchangePrices_);
}

interface FluidDexReservesResolver {
    struct Pool {
        address pool;
        address token0;
        address token1;
        uint256 fee;
    }

    /// @notice Get a Pool's address and its token addresses
    /// @param poolId_ The ID of the Pool
    /// @return pool_ The Pool data
    function getPool(uint256 poolId_) public view returns (Pool memory pool_);
}

interface FluidVaultT1Resolver {
    function getTotalVaults() public view returns (uint256);

    function getVaultAddress(uint256 vaultId_) public view returns (address vault_);

    function getAllVaultsAddresses() public view returns (address[] memory vaults_);
}

interface FluidVaultFactory {
    /// @notice                         Sets an address as allowed vault deployment logic (`deploymentLogic_`) contract or not.
    ///                                 This function can only be called by the owner.
    /// @param deploymentLogic_         The address of the vault deployment logic contract to be set.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy new type of vault.
    function setVaultDeploymentLogic(address deploymentLogic_, bool allowed_) public;

    /// @notice                         Sets an address (`vaultAuth_`) as allowed vault authorization or not for a specific vault (`vault_`).
    ///                                 This function can only be called by the owner.
    /// @param vault_                   The address of the vault for which the authorization is being set.
    /// @param vaultAuth_               The address to be set as vault authorization.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to update the specific vault config.
    function setVaultAuth(address vault_, address vaultAuth_, bool allowed_) external;
}

interface FluidVaultResolver {
    struct UserSupplyData {
        bool modeWithInterest; // true if mode = with interest, false = without interest
        uint256 supply; // user supply amount
        // the withdrawal limit (e.g. if 10% is the limit, and 100M is supplied, it would be 90M)
        uint256 withdrawalLimit;
        uint256 lastUpdateTimestamp;
        uint256 expandPercent; // withdrawal limit expand percent in 1e2
        uint256 expandDuration; // withdrawal limit expand duration in seconds
        uint256 baseWithdrawalLimit;
        // the current actual max withdrawable amount (e.g. if 10% is the limit, and 100M is supplied, it would be 10M)
        uint256 withdrawableUntilLimit;
        uint256 withdrawable; // actual currently withdrawable amount (supply - withdrawal Limit) & considering balance
    }

    struct UserBorrowData {
        bool modeWithInterest; // true if mode = with interest, false = without interest
        uint256 borrow; // user borrow amount
        uint256 borrowLimit;
        uint256 lastUpdateTimestamp;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseBorrowLimit;
        uint256 maxBorrowLimit;
        uint256 borrowableUntilLimit; // borrowable amount until any borrow limit (incl. max utilization limit)
        uint256 borrowable; // actual currently borrowable amount (borrow limit - already borrowed) & considering balance, max utilization
        uint256 borrowLimitUtilization; // borrow limit for `maxUtilization`
    }

    struct ConstantViews {
        address liquidity;
        address factory;
        address adminImplementation;
        address secondaryImplementation;
        address supplyToken;
        address borrowToken;
        uint8 supplyDecimals;
        uint8 borrowDecimals;
        uint256 vaultId;
        bytes32 liquiditySupplyExchangePriceSlot;
        bytes32 liquidityBorrowExchangePriceSlot;
        bytes32 liquidityUserSupplySlot;
        bytes32 liquidityUserBorrowSlot;
    }

    struct VaultEntireData {
        address vault;
        ConstantViews constantVariables;
        Configs configs;
        ExchangePricesAndRates exchangePricesAndRates;
        TotalSupplyAndBorrow totalSupplyAndBorrow;
        LimitsAndAvailability limitsAndAvailability;
        VaultState vaultState;
        // liquidity related data such as supply amount, limits, expansion etc.
        // only set if not smart col!
        UserSupplyData liquidityUserSupplyData;
        // liquidity related data such as borrow amount, limits, expansion etc.
        // only set if not smart debt!
        UserBorrowData liquidityUserBorrowData;
    }

    function getTotalVaults() public view returns (uint256);

    function getVaultAddress(uint256 vaultId_) public view returns (address vault_);

    function getVaultEntireData(address vault_) public view returns (VaultEntireData memory vaultData_);
}

contract PayloadIGP43 {
    struct vaultConfig {
        uint256 vaultId;
        address supplyToken;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationMaxLimit;
        uint256 liquidationPenalty;
        address oracle;
    }

    struct TokenConfig {
        uint256 baseDebtCeiling;
        uint256 maxDebtCeiling;
        uint256 baseWithdrawalLimit;
    }

    struct DexConfig {
        uint256 dexId;
        TokenConfig token0Config;
        TokenConfig token1Config;
    }

    uint256 public constant PROPOSAL_ID = 42;

    address public constant PROPOSER = 0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    IGovernorBravo public constant GOVERNOR = IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public constant TIMELOCK = ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public constant TEAM_MULTISIG = 0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    address public immutable ADDRESS_THIS;

    IFluidLiquidityAdmin public constant LIQUIDITY = IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    FluidDexReservesResolver public constant DEX_RESERVES_RESOLVER = 0x278166A9B88f166EB170d55801bE1b1d1E576330;

    FluidVaultT2DeploymentLogic public constant VAULT_T2_LOGIC; // TODO add address here

    FluidVaultT3DeploymentLogic public constant VAULT_T3_LOGIC; // TODO add address here

    FluidVaultT4DeploymentLogic public constant VAULT_T4_LOGIC; // TODO add address here

    FluidVaultFactory public constant VAULT_FACTORY = 0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d;

    address public constant FluidVaultT2Resolver; // TODO add address here

    address public constant FluidVaultT3Resolver; // TODO add address here

    address public constant FluidVaultT4Resolver; // TODO add address here

    uint256 public constant wstETH_ETH_Dex; // TODO add address here
    uint256 public constant USDC_USDT_Dex; // TODO add address here
    uint256 public constant cbBTC_WBTC_Dex; // TODO add address here

    address public constant wstETH_ETH_Smart; // TODO add address here
    address public constant ETH_USDC_USDT; // TODO add address here
    address public constant wstETH_USDC_USDT; // TODO add address here
    address public constant weETH_USDC_USDT; // TODO add address here
    address public constant WBTC_USDC_USDT; // TODO add address here
    address public constant cbBTC_USDC_USDT; // TODO add address here
    address public constant sUSDe_USDC_USDT; // TODO add address here
    address public constant cbBTC_WBTC_Smart; // TODO add address here
    address public constant cbBTC_WBTC_USDC; // TODO add address here
    address public constant cbBTC_WBTC_USDT; // TODO add address here

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

        uint256 proposedId = GOVERNOR.propose(targets, values, signatures, calldatas, description);

        require(proposedId == PROPOSAL_ID, "PROPOSAL_IS_NOT_SAME");
    }

    function execute() external {
        require(address(this) == address(TIMELOCK), "not-valid-caller");

        // Action 1: Give allowance on Liquidity Layer to initial 2 DEXes
        action1();

        // Action 2: Give allowance on Liquidity Layer to new vaults
        action2();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */

    /// @notice Action 1: Setting supply and borrow limit for Dexes
    function action1() internal {
        Pool memory pool1_ = DEX_RESERVES_RESOLVER.getPool(wstETH_ETH_Dex);
            setSupplyConfigforDex(
                pool1_.pool, pool1_.token0, pool1_.token1, dexConfigs_[i].token0Config, dexConfigs_[i].token1Config
            );
            setBorrowConfigforDex(
                pool1_.pool, pool1_.token0, pool1_.token1, dexConfigs_[i].token0Config, dexConfigs_[i].token1Config
            );

        Pool memory pool1_ = DEX_RESERVES_RESOLVER.getPool(USDC_USDT_Dex);
            setBorrowConfigforDex(
                pool1_.pool, pool1_.token0, pool1_.token1, dexConfigs_[i].token0Config, dexConfigs_[i].token1Config
            );
            
        Pool memory pool1_ = DEX_RESERVES_RESOLVER.getPool(cbBTC_WBTC_Dex);
            setSupplyConfigforDex(
                pool1_.pool, pool1_.token0, pool1_.token1, dexConfigs_[i].token0Config, dexConfigs_[i].token1Config
            );
            setBorrowConfigforDex(
                pool1_.pool, pool1_.token0, pool1_.token1, dexConfigs_[i].token0Config, dexConfigs_[i].token1Config
            );
    }

    /// @notice Action 2: Setting team multisig as vault auth in 10 vaults
    function action2() internal {
        VAULT_FACTORY.setVaultAuth(wstETH_ETH_Smart, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(ETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(wstETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(weETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(WBTC_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(sUSDe_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_Smart, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_USDC, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_USDT, TEAM_MULTISIG, true);
    }


    function setSupplyConfigforDex(
        address dex_,
        address token0_,
        address token1_,
        TokenConfig memory token0Config_,
        TokenConfig memory token1Config_
    ) internal {
        AdminModuleStructs.UserSupplyConfig[] memory supplyParams_ = new AdminModuleStructs.UserSupplyConfig[](2);

        supplyParams_[0] = AdminModuleStructs.UserSupplyConfig({
            user: dex_,
            token: token0_,
            mode: false, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseWithdrawalLimit: token0Config_.baseWithdrawalLimit
        });
        supplyParams_[1] = AdminModuleStructs.UserSupplyConfig({
            user: dex_,
            token: token1_,
            mode: false, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseWithdrawalLimit: token1Config_.baseWithdrawalLimit
        });

        LIQUIDITY.updateUserSupplyConfigs(supplyParams_);
    }

    function setBorrowConfigforDex(
        address dex_,
        address token0_,
        address token1_,
        TokenConfig memory token0Config_,
        TokenConfig memory token1Config_
    ) internal {
        AdminModuleStructs.UserBorrowConfig[] memory borrowParams_ = new AdminModuleStructs.UserBorrowConfig[](2);

        borrowParams_[0] = AdminModuleStructs.UserBorrowConfig({
            user: dex_,
            token: token0_,
            mode: false, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseDebtCeiling: token0Config_.baseDebtCeiling,
            maxDebtCeiling: token0Config_.maxDebtCeiling
        });
        borrowParams_[1] = AdminModuleStructs.UserBorrowConfig({
            user: dex_,
            token: token1_,
            mode: false, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseDebtCeiling: token1Config_.baseDebtCeiling,
            maxDebtCeiling: token1Config_.maxDebtCeiling
        });

        LIQUIDITY.updateUserBorrowConfigs(borrowParams_);
    }
}
