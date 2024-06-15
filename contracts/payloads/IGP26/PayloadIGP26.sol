pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import {BigMathMinified} from "./libraries/bigMathMinified.sol";
import {LiquiditySlotsLink} from "./libraries/liquiditySlotsLink.sol";
import {LiquidityCalcs} from "./libraries/liquidityCalcs.sol";

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

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
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

    /// @notice                         Computes the address of a vault based on its given ID (`vaultId_`).
    /// @param vaultId_                 The ID of the vault.
    /// @return vault_                  Returns the computed address of the vault.
    function getVaultAddress(
        uint256 vaultId_
    ) external view returns (address vault_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
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

    struct ConstantViews {
        address liquidity;
        address factory;
        address adminImplementation;
        address secondaryImplementation;
        address supplyToken;
        address borrowToken;
        uint8 supplyDecimals;
        uint8 borrowDecimals;
        uint vaultId;
        bytes32 liquiditySupplyExchangePriceSlot;
        bytes32 liquidityBorrowExchangePriceSlot;
        bytes32 liquidityUserSupplySlot;
        bytes32 liquidityUserBorrowSlot;
    }

    /// @notice returns all Vault constants
    function constantsView()
        external
        view
        returns (ConstantViews memory constantsView_);

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);

    struct Configs {
        uint16 supplyRateMagnifier;
        uint16 borrowRateMagnifier;
        uint16 collateralFactor;
        uint16 liquidationThreshold;
        uint16 liquidationMaxLimit;
        uint16 withdrawalGap;
        uint16 liquidationPenalty;
        uint16 borrowFee;
        address oracle;
        uint oraclePriceOperate;
        uint oraclePriceLiquidate;
        address rebalancer;
    }
}

interface IFluidOracle {
    /// @dev Deprecated. Use `getExchangeRateOperate()` and `getExchangeRateLiquidate()` instead. Only implemented for
    ///      backwards compatibility.
    function getExchangeRate() external view returns (uint256 exchangeRate_);

    /// @notice Get the `exchangeRate_` between the underlying asset and the peg asset in 1e27 for operates
    function getExchangeRateOperate()
        external
        view
        returns (uint256 exchangeRate_);

    /// @notice Get the `exchangeRate_` between the underlying asset and the peg asset in 1e27 for liquidations
    function getExchangeRateLiquidate()
        external
        view
        returns (uint256 exchangeRate_);
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

contract PayloadIGP26 {
    uint256 public constant PROPOSAL_ID = 26;

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
    IFluidReserveContract public constant FLUID_RESERVE =
        IFluidReserveContract(0x264786EF916af64a1DB19F513F24a3681734ce92);

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

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

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

        // Action 1: Clone from old vault config to new vault
        action1();

        // Action 2: Collect revenue from Liquditiy Layer
        action2();
    }

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Clone from old vault config to new vault
    function action1() internal {
        for (uint oldVaultId = 1; oldVaultId <= 10; oldVaultId++) {
            cloneVault(oldVaultId);
        }
    }

    /// @notice Action 2: Collect revenue from Liquditiy Layer
    function action2() internal {
        address[] memory tokens = new address[](4);

        tokens[0] = ETH_ADDRESS;
        tokens[1] = wstETH_ADDRESS;
        tokens[2] = USDC_ADDRESS;
        tokens[3] = USDT_ADDRESS;

        LIQUIDITY.collectRevenue(tokens);
    }

    /***********************************|
    |     Proposal Payload Helpers      |
    |__________________________________*/

    function getUserSupplyDataAndSetLimits(
        address token_,
        address oldVault_,
        address newVault_,
        uint256 withdrawalLimit
    )
        internal
        view
        returns (AdminModuleStructs.UserSupplyConfig memory config_)
    {
        uint256 userSupplyData_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_USER_SUPPLY_DOUBLE_MAPPING_SLOT,
                oldVault_,
                token_
            )
        );

        (uint256 supplyExchangePrice, ) = LiquidityCalcs.calcExchangePrices(
            LIQUIDITY.readFromStorage(
                LiquiditySlotsLink.calculateMappingStorageSlot(
                    LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                    token_
                )
            )
        );

        config_ = AdminModuleStructs.UserSupplyConfig({
            user: newVault_,
            token: token_,
            mode: uint8(userSupplyData_ & 1),
            expandPercent: (userSupplyData_ >>
                LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_PERCENT) & X14,
            expandDuration: (userSupplyData_ >>
                LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_DURATION) & X24,
            baseWithdrawalLimit: (withdrawalLimit * 1e12) / supplyExchangePrice
        });
    }

    function getUserBorrowDataAndSetLimits(
        address token_,
        address oldVault_,
        address newVault_,
        uint256 baseLimit,
        uint256 maxLimit
    )
        internal
        view
        returns (AdminModuleStructs.UserBorrowConfig memory config_)
    {
        uint256 userBorrowData_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_USER_BORROW_DOUBLE_MAPPING_SLOT,
                oldVault_,
                token_
            )
        );

        (, uint256 borrowExchangePrice) = LiquidityCalcs.calcExchangePrices(
            LIQUIDITY.readFromStorage(
                LiquiditySlotsLink.calculateMappingStorageSlot(
                    LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                    token_
                )
            )
        );

        config_ = AdminModuleStructs.UserBorrowConfig({
            user: newVault_,
            token: token_,
            mode: uint8(userBorrowData_ & 1),
            expandPercent: (userBorrowData_ >>
                LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_PERCENT) & X14,
            expandDuration: (userBorrowData_ >>
                LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_DURATION) & X24,
            baseDebtCeiling: (baseLimit * 1e12) / borrowExchangePrice,
            maxDebtCeiling: (maxLimit * 1e12) / borrowExchangePrice
        });
    }

    function getAllowance(
        address token
    ) internal pure returns (uint256, uint256, uint256) {
        if (token == ETH_ADDRESS) {
            return (3 * 1e18, 4 * 1e18, 0);
        } else if (token == wstETH_ADDRESS) {
            return (2.33 * 1e18, 3.5 * 1e18, 0.03 * 1e18);
        } else if (token == weETH_ADDRESS) {
            return (2.6 * 1e18, 3.95 * 1e18, 0.03 * 1e18);
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            return (10_000 * 1e6, 15_000 * 1e6, 100 * 1e6);
        } else if (token == sUSDe_ADDRESS) {
            return (9_200 * 1e18, 13_900 * 1e18, 100 * 1e18);
        } else {
            revert("no allowance found");
        }
    }

    function getOracleAddress(uint256 vaultId) internal pure returns (address) {
        if (vaultId == 11) {
            return 0x5b2860C6D6F888319C752aaCDaf8165C21095E3a; // VAULT_ETH_USDC
        } else if (vaultId == 12) {
            return 0x7eA20E1FB456AF31C6425813bFfD4Ef6E0A4C86E; // VAULT_ETH_USDT
        } else if (vaultId == 13) {
            return 0xadE0948e2431DEFB87e75760e94f190cbF35E95b; // VAULT_WSTETH_ETH
        } else if (vaultId == 14) {
            return 0xc5911Fa3917c507fBEbAb910C8b47cBdD3Ce147e; // VAULT_WSTETH_USDC
        } else if (vaultId == 15) {
            return 0x38aE6fa3d6376D86D1EE591364CD4b45C99adE22; // VAULT_WSTETH_USDT
        } else if (vaultId == 16) {
            return 0xEA0C58bE3133Cb7f035faCF45cb1d4F84CF178B4; // VAULT_WEETH_WSTETH
        } else if (vaultId == 17) {
            return 0x72DB9B7Bd2b0BC282708E85E16123023b32de6A9; // VAULT_SUSDE_USDC
        } else if (vaultId == 18) {
            return 0x72DB9B7Bd2b0BC282708E85E16123023b32de6A9; // VAULT_SUSDE_USDT
        } else if (vaultId == 19) {
            return 0xda8a70b9533DEBE425F8A3b2B33bc09c0415e5FE; // VAULT_WEETH_USDC
        } else if (vaultId == 20) {
            return 0x32eE0cB3587C6e9f8Ad2a0CF83B6Cf326848b7c6; // VAULT_WEETH_USDT
        } else {
            revert("no oracle address");
        }
    }

    function getVaultConfig(
        address vault
    ) internal view returns (IFluidVaultT1.Configs memory configs) {
        uint vaultVariables2 = IFluidVaultT1(vault).readFromStorage(
            bytes32(uint256(1))
        );
        configs.supplyRateMagnifier = uint16(vaultVariables2 & X16);
        configs.borrowRateMagnifier = uint16((vaultVariables2 >> 16) & X16);
        configs.collateralFactor = (uint16((vaultVariables2 >> 32) & X10)) * 10;
        configs.liquidationThreshold =
            (uint16((vaultVariables2 >> 42) & X10)) *
            10;
        configs.liquidationMaxLimit = (uint16((vaultVariables2 >> 52) & X10) *
            10);
        configs.withdrawalGap = uint16((vaultVariables2 >> 62) & X10) * 10;
        configs.liquidationPenalty = uint16((vaultVariables2 >> 72) & X10);
        configs.borrowFee = uint16((vaultVariables2 >> 82) & X10);
        configs.oracle = address(uint160(vaultVariables2 >> 96));
    }

    struct CloneVaultStruct {
        address oldVaultAddress;
        address newVaultAddress;
        address newOracleAddress;
        address[] protocols;
        address[] tokens;
        uint256[] amounts;
        uint256 supplyBaseAllowance;
        uint256 supplyReserveAllowance;
        uint256 borrowBaseAllowance;
        uint256 borrowMaxAllowance;
        uint256 borrowReserveAllowance;
    }

    function cloneVault(uint256 oldVaultId) internal {
        CloneVaultStruct memory data;

        data.oldVaultAddress = VAULT_T1_FACTORY.getVaultAddress(oldVaultId);
        data.newVaultAddress = VAULT_T1_FACTORY.getVaultAddress(
            oldVaultId + 10
        );

        IFluidVaultT1.ConstantViews memory oldConstants = IFluidVaultT1(
            data.oldVaultAddress
        ).constantsView();
        IFluidVaultT1.ConstantViews memory newConstants = IFluidVaultT1(
            data.newVaultAddress
        ).constantsView();

        data.newOracleAddress = getOracleAddress(oldVaultId + 10);

        (
            data.supplyBaseAllowance,
            ,
            data.supplyReserveAllowance
        ) = getAllowance(newConstants.supplyToken);
        (
            data.borrowBaseAllowance,
            data.borrowMaxAllowance,
            data.borrowReserveAllowance
        ) = getAllowance(newConstants.borrowToken);

        {
            require(
                oldConstants.supplyToken == newConstants.supplyToken,
                "not-same-supply-token"
            );
            require(
                oldConstants.borrowToken == newConstants.borrowToken,
                "not-same-borrow-token"
            );
        }

        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = getUserSupplyDataAndSetLimits(
                newConstants.supplyToken,
                data.oldVaultAddress,
                data.newVaultAddress,
                data.supplyBaseAllowance
            );

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = getUserBorrowDataAndSetLimits(
                newConstants.borrowToken,
                data.oldVaultAddress,
                data.newVaultAddress,
                data.borrowBaseAllowance,
                data.borrowMaxAllowance
            );

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }

        // Clone core settings from old vault to new vault.
        {
            IFluidVaultT1.Configs memory configs = getVaultConfig(
                data.oldVaultAddress
            );

            {
                require(
                    (IFluidOracle(configs.oracle).getExchangeRate() ==
                        IFluidOracle(data.newOracleAddress)
                            .getExchangeRateOperate()) &&
                        (IFluidOracle(data.newOracleAddress)
                            .getExchangeRateOperate() ==
                            IFluidOracle(data.newOracleAddress)
                                .getExchangeRateLiquidate()),
                    "oracle exchangePrice is not same"
                );
            }

            IFluidVaultT1(data.newVaultAddress).updateCoreSettings(
                configs.supplyRateMagnifier, //     supplyRateMagnifier
                configs.borrowRateMagnifier, //     borrowRateMagnifier
                configs.collateralFactor, //        collateralFactor
                configs.liquidationThreshold, //    liquidationThreshold
                configs.liquidationMaxLimit, //     liquidationMaxLimit
                configs.withdrawalGap, //           withdrawGap
                configs.liquidationPenalty, //      liquidationPenalty
                configs.borrowFee //                borrowFee
            );
        }

        // Update oracle on new vault.
        {
            IFluidVaultT1(data.newVaultAddress).updateOracle(
                data.newOracleAddress
            );
        }

        // Update rebalancer on new vault.
        {
            IFluidVaultT1(data.newVaultAddress).updateRebalancer(
                0x264786EF916af64a1DB19F513F24a3681734ce92
            );
        }

        // Approve new vault to spend the reserves dust tokens
        {
            uint256 len = data.supplyReserveAllowance == 0 ||
                data.borrowReserveAllowance == 0
                ? 1
                : 2;
            uint256 i = 0;

            data.protocols = new address[](len);
            data.tokens = new address[](len);
            data.amounts = new uint256[](len);

            {
                if (data.supplyReserveAllowance != 0) {
                    data.protocols[i] = data.newVaultAddress;
                    data.tokens[i] = newConstants.supplyToken;
                    data.amounts[i] = data.supplyReserveAllowance;
                    i++;
                }

                if (data.borrowReserveAllowance != 0) {
                    data.protocols[i] = data.newVaultAddress;
                    data.tokens[i] = newConstants.borrowToken;
                    data.amounts[i] = data.borrowReserveAllowance;
                }

                FLUID_RESERVE.approve(
                    data.protocols,
                    data.tokens,
                    data.amounts
                );
            }
        }
    }
}
