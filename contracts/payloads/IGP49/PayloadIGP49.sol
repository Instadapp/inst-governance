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

    function balanceOf(address account) external view returns (uint256);
}

interface FluidDexFactory {
    /// @notice                         Computes the address of a dex based on its given ID (`dexId_`).
    /// @param dexId_                   The ID of the dex.
    /// @return dex_                    Returns the computed address of the dex.
    function getDexAddress(uint256 dexId_) external view returns (address dex_);

    function setDexAuth(address dex_, address dexAuth_, bool allowed_) external;

    function owner() external view returns (address);
}

contract PayloadIGP49 {
    uint256 public constant PROPOSAL_ID = 49;

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
    FluidDexFactory public constant DEX_FACTORY =
        FluidDexFactory(0x91716C4EDA1Fb55e84Bf8b4c7085f84285c19085);

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
    address internal constant USDe_ADDRESS =
        0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;

    address internal constant GHO_ADDRESS =
        0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

    address internal constant WBTC_ADDRESS =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant cbBTC_ADDRESS =
        0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    address internal constant F_GHO_ADDRESS =
        0x6A29A46E21C730DcA1d8b23d637c101cec605C5B;

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

        // Action 1: Increase ETH-USDC, wBTC-ETH, cbBTC-ETH, USDe-USDC Dex pools allowance on Liquidity.
        action1();

        // Action 2: Config USDe vaults
        action2();
    }

    function verifyProposal() external view {}

    /**
     * |
     * |     Proposal Payload Actions      |
     * |__________________________________
     */


    /// @notice Action 1: Increase ETH-USDC, wBTC-ETH, cbBTC-ETH, USDe-USDC Dex pools allowance on Liquidity.
    function action1() internal {
        {
            // ETH-USDC
            Dex memory DEX_ETH_USDC = Dex({
                dex: getDexAddress(5),
                tokenA: ETH_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 6_000_000 // $6M
            });
            setDexLimits(DEX_ETH_USDC); // Smart Collateral & Smart Debt
        }

        {
            // WBTC-ETH
            Dex memory DEX_WBTC_ETH = Dex({
                dex: getDexAddress(6),
                tokenA: WBTC_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 6_000_000 // $6M
            });
            setDexLimits(DEX_WBTC_ETH); // Smart Collateral & Smart Debt
        }

        {
            // cbBTC-ETH
            Dex memory DEX_cbBTC_ETH = Dex({
                dex: getDexAddress(7),
                tokenA: cbBTC_ADDRESS,
                tokenB: ETH_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 6_000_000 // $6M
            });
            setDexLimits(DEX_cbBTC_ETH); // Smart Collateral & Smart Debt
        }

        {
            // USDe-USDC
            Dex memory DEX_USDe_USDC = Dex({
                dex: getDexAddress(8),
                tokenA: USDe_ADDRESS,
                tokenB: USDC_ADDRESS,
                smartCollateral: true,
                smartDebt: true,
                baseWithdrawalLimitInUSD: 7_500_000, // $7.5M
                baseBorrowLimitInUSD: 5_000_000, // $5M
                maxBorrowLimitInUSD: 6_000_000 // $6M
            });
            setDexLimits(DEX_USDe_USDC); // Smart Collateral & Smart Debt
        }
    }

    /// @notice Action 2: Config USDe vaults
    function action2() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 7_500_000, // $7.5M
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
            collateralFactor: 0,
            liquidationThreshold: 0,
            liquidationMaxLimit: 0,
            withdrawGap: 0,
            liquidationPenalty: 0,
            borrowFee: 0, // 0%
            oracle: address(0)
        });

        // Config USDe/USDC vault.
        {
            vaultConfig.vaultId = 66;
            vaultConfig.supplyToken = USDe_ADDRESS;
            vaultConfig.borrowToken = USDC_ADDRESS;

            vaultConfig.collateralFactor = 0 * 1e2; // 0
            vaultConfig.liquidationThreshold = 0 * 1e2; // 0
            vaultConfig.liquidationMaxLimit = 0 * 1e2; // 0
            vaultConfig.withdrawGap = 0 * 1e2; // 0
            vaultConfig.liquidationPenalty = 0 * 1e2; // 0

            vaultConfig.oracle = address(0x8E5FA052eE010BCbAc7d00D859100B48a6A40967);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config USDe/USDT vault.
        {
            vaultConfig.vaultId = 67;
            vaultConfig.supplyToken = USDe_ADDRESS;
            vaultConfig.borrowToken = USDT_ADDRESS;

            vaultConfig.collateralFactor = 0 * 1e2; // 0
            vaultConfig.liquidationThreshold = 0 * 1e2; // 0
            vaultConfig.liquidationMaxLimit = 0 * 1e2; // 0
            vaultConfig.withdrawGap = 0 * 1e2; // 0
            vaultConfig.liquidationPenalty = 0 * 1e2; // 0

            vaultConfig.oracle = address(0x8E5FA052eE010BCbAc7d00D859100B48a6A40967);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config USDe/GHO vault.
        {
            vaultConfig.vaultId = 68;
            vaultConfig.supplyToken = USDe_ADDRESS;
            vaultConfig.borrowToken = GHO_ADDRESS;

            vaultConfig.collateralFactor = 0 * 1e2; // 0
            vaultConfig.liquidationThreshold = 0 * 1e2; // 0
            vaultConfig.liquidationMaxLimit = 0 * 1e2; // 0
            vaultConfig.withdrawGap = 0 * 1e2; // 0
            vaultConfig.liquidationPenalty = 0 * 1e2; // 0

            vaultConfig.oracle = address(0xAd3fEaE8c608681E989D393b48FaEE71e664050A);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config ETH/USDe vault.
        {
            vaultConfig.vaultId = 69;
            vaultConfig.supplyToken = ETH_ADDRESS;
            vaultConfig.borrowToken = USDe_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 90 * 1e2; // 90%
            vaultConfig.liquidationMaxLimit = 93 * 1e2; // 93%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 2.5 * 1e2; // 2.5%

            vaultConfig.oracle = address(0x4A67E941Ccd89806Ba2397BA336d791759D512ca);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config wstETH/USDe vault.
        {
            vaultConfig.vaultId = 70;
            vaultConfig.supplyToken = wstETH_ADDRESS;
            vaultConfig.borrowToken = USDe_ADDRESS;

            vaultConfig.collateralFactor = 82 * 1e2; // 82%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(0x4908422a87111394c05751dFfaE4A64BE18B05E3);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }
        
        // Config weETH/USDe vault.
        {
            vaultConfig.vaultId = 71;
            vaultConfig.supplyToken = weETH_ADDRESS;
            vaultConfig.borrowToken = USDe_ADDRESS;

            vaultConfig.collateralFactor = 77 * 1e2; // 77%
            vaultConfig.liquidationThreshold = 82 * 1e2; // 82%
            vaultConfig.liquidationMaxLimit = 90 * 1e2; // 90%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(0x743FB38FD621fc836F3383531Fb576e8a35059E1);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config wBTC/USDe vault.
        {
            vaultConfig.vaultId = 72;
            vaultConfig.supplyToken = WBTC_ADDRESS;
            vaultConfig.borrowToken = USDe_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(0x538fec4B539ad20B55Ba2F08b58bc28bC669Adc3);

            address vault_ = configVault(vaultConfig);

            require(vault_ != address(0), "vault-not-deployed");
        }

        // Config cbBTC/USDe vault.
        {
            vaultConfig.vaultId = 73;
            vaultConfig.supplyToken = cbBTC_ADDRESS;
            vaultConfig.borrowToken = USDe_ADDRESS;

            vaultConfig.collateralFactor = 85 * 1e2; // 85%
            vaultConfig.liquidationThreshold = 88 * 1e2; // 88%
            vaultConfig.liquidationMaxLimit = 92.5 * 1e2; // 92.5%
            vaultConfig.withdrawGap = 5 * 1e2; // 5%
            vaultConfig.liquidationPenalty = 3 * 1e2; // 3%

            vaultConfig.oracle = address(0x0e701AFc1feF3E963a42cC1Ccf81BEAE0fEbf20A);

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

    function getDexAddress(uint256 dexId_) public view returns (address) {
        return DEX_FACTORY.getDexAddress(dexId_);
    }

    struct SupplyProtocolConfig {
        address protocol;
        address supplyToken;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseWithdrawalLimitInUSD;
    }

    struct BorrowProtocolConfig {
        address protocol;
        address borrowToken;
        uint256 expandPercent;
        uint256 expandDuration;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
    }

    function setDexLimits(Dex memory dex_) internal {
        // Smart Collateral
        if (dex_.smartCollateral) {
            SupplyProtocolConfig memory protocolConfigTokenA_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseWithdrawalLimitInUSD: dex_.baseWithdrawalLimitInUSD
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);
        }

        // Smart Debt
        if (dex_.smartDebt) {
            BorrowProtocolConfig memory protocolConfigTokenA_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenA,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig memory protocolConfigTokenB_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenB,
                expandPercent: 50 * 1e2, // 50%
                expandDuration: 1 hours, // 1 hour
                baseBorrowLimitInUSD: dex_.baseBorrowLimitInUSD,
                maxBorrowLimitInUSD: dex_.maxBorrowLimitInUSD
            });

            setBorrowProtocolLimits(protocolConfigTokenB_);
        }
    }

    function setSupplyProtocolLimits(
        SupplyProtocolConfig memory protocolConfig_
    ) internal {
        {
            // Supply Limits
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(protocolConfig_.protocol),
                token: protocolConfig_.supplyToken,
                mode: 1,
                expandPercent: protocolConfig_.expandPercent,
                expandDuration: protocolConfig_.expandDuration,
                baseWithdrawalLimit: getRawAmount(
                    protocolConfig_.supplyToken,
                    0,
                    protocolConfig_.baseWithdrawalLimitInUSD,
                    true
                )
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }
    }

    function setBorrowProtocolLimits(
        BorrowProtocolConfig memory protocolConfig_
    ) internal {
        {
            // Borrow Limits
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = AdminModuleStructs.UserBorrowConfig({
                user: address(protocolConfig_.protocol),
                token: protocolConfig_.borrowToken,
                mode: 1,
                expandPercent: protocolConfig_.expandPercent,
                expandDuration: protocolConfig_.expandDuration,
                baseDebtCeiling: getRawAmount(
                    protocolConfig_.borrowToken,
                    0,
                    protocolConfig_.baseBorrowLimitInUSD,
                    false
                ),
                maxDebtCeiling: getRawAmount(
                    protocolConfig_.borrowToken,
                    0,
                    protocolConfig_.maxBorrowLimitInUSD,
                    false
                )
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }
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
            usdPrice = 1.11 * 1e2;
            decimals = 18;
        } else if (token == sUSDs_ADDRESS) {
            usdPrice = 1.12 * 1e2;
            decimals = 18;
        } else if (token == GHO_ADDRESS || token == USDe_ADDRESS) {
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
