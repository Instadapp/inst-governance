pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "../libraries/bigMathMinified.sol";
import {LiquiditySlotsLink} from "../libraries/liquiditySlotsLink.sol";
import {LiquidityCalcs} from "../libraries/liquidityCalcs.sol";

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
    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

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

interface IFluidDexFactory {
    /// @notice                       Computes the address of a dex based on its given ID (`dexId_`).
    /// @param dexId_                 The ID of the dex.
    /// @return dex_                  Returns the computed address of the dex.
    function getDexAddress(uint256 dexId_) external view returns (address dex_);
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

    function getVaultAddress(
        uint256 vaultId_
    ) external view returns (address vault_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
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

interface IERC20 {
    function allowance(
        address spender,
        address caller
    ) external view returns (uint256);
}

contract PayloadIGP40 {
    uint256 public constant PROPOSAL_ID = 40;

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
    ITimelock public immutable TIMELOCK =
        ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    IFluidLiquidityAdmin public constant LIQUIDITY =
        IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);
    IFluidVaultT1Factory public constant VAULT_T1_FACTORY =
        IFluidVaultT1Factory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);
    IFluidReserveContract public constant FLUID_RESERVE =
        IFluidReserveContract(0x264786EF916af64a1DB19F513F24a3681734ce92);

    IFluidDexFactory public constant FLUID_DEX_FACTORY =
        IFluidDexFactory(0x93DD426446B5370F094a1e31f19991AAA6Ac0bE0);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

    address public constant cbBTC_ADDRESS =
        0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    uint256 internal constant X8 = 0xff;
    uint256 internal constant X10 = 0x3ff;
    uint256 internal constant X14 = 0x3fff;
    uint256 internal constant X15 = 0x7fff;
    uint256 internal constant X16 = 0xffff;
    uint256 internal constant X18 = 0x3ffff;
    uint256 internal constant X24 = 0xffffff;
    uint256 internal constant X64 = 0xffffffffffffffff;

    uint256 internal constant DEFAULT_EXPONENT_SIZE = 8;
    uint256 internal constant DEFAULT_EXPONENT_MASK = 0xff;

    address public constant F_USDT = 0x5C20B550819128074FD538Edf79791733ccEdd18;
    address public constant F_USDC = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33;

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

        // Action 1: call executePayload on timelock contract to execute payload related Fluid
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

        /// @notice Action 1: Set cbBTC token config and market rate curve on liquidity.
        action1();

        /// @notice Action 2: Config cbBTC/ETH and ETH/cbBTC
        action2();

        /// @notice Action 3: Config cbBTC/USDC and cbBTC/USDT
        action3();

        /// @notice Action 4: Config wstETH/cbBTC and weETH/cbBTC
        action4();

        /// @notice Action 5: Add new LendingRewards contracts
        action5();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Set cbBTC token config and market rate curve on liquidity.
    function action1() internal {
        {
            AdminModuleStructs.RateDataV1Params[]
                memory params_ = new AdminModuleStructs.RateDataV1Params[](1);

            params_[0] = AdminModuleStructs.RateDataV1Params({
                token: cbBTC_ADDRESS, // cbBTC
                kink: 80 * 1e2, // 80%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink: 5 * 1e2, // 5%
                rateAtUtilizationMax: 100 * 1e2 // 100%
            });

            LIQUIDITY.updateRateDataV1s(params_);
        }
    }

    /// @notice Action 2: Config cbBTC/ETH and ETH/cbBTC
    function action2() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M
            supplyBaseLimit: 0,
            borrowToken: address(0),
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowBaseLimit: 0,
            borrowMaxLimitInUSD: 20_000_000, // $20M
            borrowMaxLimit: 0,
            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 88 * 1e2, // 88%
            liquidationThreshold: 91 * 1e2, // 91%
            liquidationMaxLimit: 94 * 1e2, // 94%
            withdrawGap: 5 * 1e2, // 5%
            liquidationPenalty: 2 * 1e2, // 2%
            borrowFee: 0 * 1e2, // 0%
            oracle: address(0)
        });

        // Config cbBTC/ETH vault.
        {
            vaultConfig.vaultId = 28;
            vaultConfig.supplyToken = cbBTC_ADDRESS;
            vaultConfig.borrowToken = ETH_ADDRESS;

            vaultConfig.oracle = address(
                0x5D9bF2026dc5C248B785aC760ab6d3CF7A6C93cc
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config ETH/cbBTC vault.
        {
            vaultConfig.vaultId = 31;
            vaultConfig.supplyToken = ETH_ADDRESS;
            vaultConfig.borrowToken = cbBTC_ADDRESS;

            vaultConfig.oracle = address(
                0xdB94DD822bAaa80f8B339392bed994cdEA72D775
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }
    }

    /// @notice Action 3: Config cbBTC/USDC and cbBTC/USDT.
    function action3() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: cbBTC_ADDRESS,
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M
            supplyBaseLimit: 0,
            borrowToken: address(0),
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowBaseLimit: 0,
            borrowMaxLimitInUSD: 20_000_000, // $20M
            borrowMaxLimit: 0,
            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 80 * 1e2, // 80%
            liquidationThreshold: 85 * 1e2, // 85%
            liquidationMaxLimit: 90 * 1e2, // 90%
            withdrawGap: 5 * 1e2, // 5%
            liquidationPenalty: 0 * 1e2,
            borrowFee: 0 * 1e2, // 0%
            oracle: address(0)
        });

        // Config cbBTC/USDC vault.
        {
            vaultConfig.vaultId = 29;
            vaultConfig.borrowToken = USDC_ADDRESS;

            vaultConfig.liquidationPenalty = 3 * 1e2;

            vaultConfig.oracle = address(
                0x390421d1Fe8e238FFd9Ef86563CBF76F348CdD92
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config cbBTC/USDT vault.
        {
            vaultConfig.vaultId = 30;
            vaultConfig.borrowToken = USDT_ADDRESS;

            vaultConfig.liquidationPenalty = 4 * 1e2;

            vaultConfig.oracle = address(
                0xF38776BfEf1E2c395f80733045E4D2BCFE98f97a
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }
    }

    /// @notice Action 4: Config wstETH/cbBTC and weETH/cbBTC.
    function action4() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M
            supplyBaseLimit: 0,
            borrowToken: cbBTC_ADDRESS,
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowBaseLimit: 0,
            borrowMaxLimitInUSD: 20_000_000, // $20M
            borrowMaxLimit: 0,
            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 0 * 1e2, //
            liquidationThreshold: 0 * 1e2, //
            liquidationMaxLimit: 0 * 1e2, //
            withdrawGap: 5 * 1e2, // 5%
            liquidationPenalty: 0,
            borrowFee: 0 * 1e2, // 0%
            oracle: address(0)
        });

        // Config wstETH/cbBTC vault.
        {
            vaultConfig.vaultId = 33;
            vaultConfig.supplyToken = wstETH_ADDRESS;

            vaultConfig.collateralFactor = 88 * 1e2;
            vaultConfig.liquidationThreshold = 90 * 1e2;
            vaultConfig.liquidationMaxLimit = 93 * 1e2;

            vaultConfig.liquidationPenalty = 2 * 1e2;

            vaultConfig.oracle = address(
                0x922c2d3Ef36CC02d5053645309C924925c03c902
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config weETH/cbBTC vault.
        {
            vaultConfig.vaultId = 32;
            vaultConfig.supplyToken = weETH_ADDRESS;

            vaultConfig.collateralFactor = 80 * 1e2;
            vaultConfig.liquidationThreshold = 85 * 1e2;
            vaultConfig.liquidationMaxLimit = 90 * 1e2;

            vaultConfig.liquidationPenalty = 5 * 1e2;

            vaultConfig.oracle = address(
                0x5DdC7E208958a9B8DC595e40859E6b611fdC44cA
            );

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }
    }

    /// @notice Action 5: Add new LendingRewards contracts
    function action5() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        {
            /// fUSDC
            IFTokenAdmin(F_USDC).updateRewards(
                0x6cb89F03c444AF5De1A6d9665BBaAcbFfC3EBE83
            );

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDC
            );

            protocols[0] = F_USDC;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (200_000 * 1e6);
        }

        {
            /// fUSDT
            IFTokenAdmin(F_USDT).updateRewards(
                0x6cb89F03c444AF5De1A6d9665BBaAcbFfC3EBE83
            );

            uint256 allowance = IERC20(USDT_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDT
            );

            protocols[1] = F_USDT;
            tokens[1] = USDT_ADDRESS;
            amounts[1] = allowance + (200_000 * 1e6);
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /***********************************|
    |     Proposal Payload Helpers      |
    |__________________________________*/

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
        vault_ = VAULT_T1_FACTORY.getVaultAddress(vaultConfig.vaultId);

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
        if (amount > 0 && amountInUSD > 0)
            revert("both usd and amount are not zero");
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
            usdPrice = 2_350;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = 2_750;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = 2_450;
            decimals = 18;
        } else if (token == cbBTC_ADDRESS) {
            usdPrice = 58_500;
            decimals = 8;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = 1;
            decimals = 6;
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
                (usdPrice * exchangePrice);
        }
    }
}
