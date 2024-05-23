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

    /// @notice updates the supply rate magnifier to `supplyRateMagnifier_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateSupplyRateMagnifier(uint supplyRateMagnifier_) external;

    /// @notice updates the borrow rate magnifier to `borrowRateMagnifier_`. Input in 1e2 (1% = 100, 100% = 10_000).
    function updateBorrowRateMagnifier(uint borrowRateMagnifier_) external;
}

contract PayloadIGP24 {
    uint256 public constant PROPOSAL_ID = 24;

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

    IFluidReserveContract public constant FLUID_RESERVE =
        IFluidReserveContract(0x264786EF916af64a1DB19F513F24a3681734ce92);

    address public constant F_USDT = 0x5C20B550819128074FD538Edf79791733ccEdd18;
    address public constant F_USDC = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33;
    address public constant F_WSTETH = 0x2411802D8BEA09be0aF8fD8D08314a63e706b29C;

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

        // Action 1: Approve fUSDC and fUSDT protocols to spend the reserves tokens.
        action1();

        // Action 2: Revoke protocols to spend the reserves tokens
        action2();

        // Action 3: Approve new protocols to spend the reserves dust tokens
        action3();

        // Action 4: closure of old vaults
        action4();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Approve fUSDC and fUSDT protocols to spend the reserves tokens
    function action1() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        // fUSDC
        protocols[0] = F_USDC;
        tokens[0] = USDC_ADDRESS;
        amounts[0] = 320_000 * 1e6; // 320k USDC

        // fUSDT
        protocols[1] = F_USDT;
        tokens[1] = USDT_ADDRESS;
        amounts[1] = 320_000 * 1e6; // 320k USDT

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /// @notice Action 2: Revoke old protocols to spend the reserves tokens
    function action2() internal {
        address[] memory protocols = new address[](7);
        address[] memory tokens = new address[](7);

        address OLD_VAULT_ETH_USDC = 0x5eA9A2B42Bc9aC8CAC76E19F0Fcd5C1b06950807;
        address OLD_VAULT_ETH_USDT = 0xE53794f2ed0839F24170079A9F3c5368147F6c81;
        address OLD_VAULT_WSTETH_ETH = 0x28680f14C4Bb86B71119BC6e90E4e6D87E6D1f51;
        address OLD_VAULT_WSTETH_USDC = 0x460143a489729a3cA32DeA82fa48ea61175accbc;
        address OLD_VAULT_WSTETH_USDT = 0x2B251211f5Ff0A753A8d5B9411d736875174f375;

        // OLD_VAULT_ETH_USDC
        protocols[0] = OLD_VAULT_ETH_USDC;
        tokens[0] = USDC_ADDRESS;

        // OLD_VAULT_ETH_USDT
        protocols[1] = OLD_VAULT_ETH_USDT;
        tokens[1] = USDT_ADDRESS;

        // OLD_VAULT_WSTETH_ETH
        protocols[2] = OLD_VAULT_WSTETH_ETH;
        tokens[2] = wstETH_ADDRESS;

        // OLD_VAULT_WSTETH_USDC
        {
            protocols[3] = OLD_VAULT_WSTETH_USDC;
            tokens[3] = wstETH_ADDRESS;

            protocols[4] = OLD_VAULT_WSTETH_USDC;
            tokens[4] = USDC_ADDRESS;
        }

        // OLD_VAULT_WSTETH_USDT
        {
            protocols[5] = OLD_VAULT_WSTETH_USDT;
            tokens[5] = wstETH_ADDRESS;

            protocols[6] = OLD_VAULT_WSTETH_USDT;
            tokens[6] = USDT_ADDRESS;
        }

        FLUID_RESERVE.revoke(protocols, tokens);
    }

    /// @notice Action 3: Approve new protocols to spend the reserves dust tokens
    function action3() internal {
        address[] memory protocols = new address[](11);
        address[] memory tokens = new address[](11);
        uint256[] memory amounts = new uint256[](11);

        address VAULT_weETH_wstETH = 0x40D9b8417E6E1DcD358f04E3328bCEd061018A82;
        address VAULT_sUSDe_USDC = 0x4045720a33193b4Fe66c94DFbc8D37B0b4D9B469;
        address VAULT_sUSDe_USDT = 0xBFADEA65591235f38809076e14803Ac84AcF3F97;
        address VAULT_weETH_USDC = 0xf55B8e9F0c51Ace009f4b41d03321675d4C643b3;
        address VAULT_weETH_USDT = 0xdF16AdaF80584b2723F3BA1Eb7a601338Ba18c4e;

        // VAULT_weETH_wstETH
        {
            protocols[0] = VAULT_weETH_wstETH;
            tokens[0] = weETH_ADDRESS;
            amounts[0] = 0.03 * 1e18;

            protocols[1] = VAULT_weETH_wstETH;
            tokens[1] = wstETH_ADDRESS;
            amounts[1] = 0.03 * 1e18;
        }

        // VAULT_sUSDe_USDC
        {
            protocols[2] = VAULT_sUSDe_USDC;
            tokens[2] = sUSDe_ADDRESS;
            amounts[2] = 100 * 1e18;

            protocols[3] = VAULT_sUSDe_USDC;
            tokens[3] = USDC_ADDRESS;
            amounts[3] = 100 * 1e6;
        }

        // VAULT_sUSDe_USDT
        {
            protocols[4] = VAULT_sUSDe_USDT;
            tokens[4] = sUSDe_ADDRESS;
            amounts[4] = 100 * 1e18;

            protocols[5] = VAULT_sUSDe_USDT;
            tokens[5] = USDT_ADDRESS;
            amounts[5] = 100 * 1e6;
        }

        // VAULT_weETH_USDC
        {
            protocols[6] = VAULT_weETH_USDC;
            tokens[6] = weETH_ADDRESS;
            amounts[6] = 0.03 * 1e18;

            protocols[7] = VAULT_weETH_USDC;
            tokens[7] = USDC_ADDRESS;
            amounts[7] = 100 * 1e6;
        }

        // VAULT_weETH_USDT
        {
            protocols[8] = VAULT_weETH_USDT;
            tokens[8] = weETH_ADDRESS;
            amounts[8] = 0.03 * 1e18;

            protocols[9] = VAULT_weETH_USDT;
            tokens[9] = USDT_ADDRESS;
            amounts[9] = 100 * 1e6;
        }

        // F_WSTETH
        {
            protocols[10] = F_WSTETH;
            tokens[10] = wstETH_ADDRESS;
            amounts[10] = 0.03 * 1e18;
        }

        FLUID_RESERVE.approve(protocols, tokens, amounts);
    }

    /// @notice Action 4: closure of old vaults
    function action4() internal {
        address OLD_VAULT_ETH_USDC = 0x5eA9A2B42Bc9aC8CAC76E19F0Fcd5C1b06950807;
        address OLD_VAULT_ETH_USDT = 0xE53794f2ed0839F24170079A9F3c5368147F6c81;
        address OLD_VAULT_WSTETH_ETH = 0x28680f14C4Bb86B71119BC6e90E4e6D87E6D1f51;
        address OLD_VAULT_WSTETH_USDC = 0x460143a489729a3cA32DeA82fa48ea61175accbc;
        address OLD_VAULT_WSTETH_USDT = 0x2B251211f5Ff0A753A8d5B9411d736875174f375;

        closeVault(OLD_VAULT_ETH_USDC, ETH_ADDRESS, USDC_ADDRESS);
        closeVault(OLD_VAULT_ETH_USDT, ETH_ADDRESS, USDT_ADDRESS);
        closeVault(OLD_VAULT_WSTETH_ETH, wstETH_ADDRESS, ETH_ADDRESS);
        closeVault(OLD_VAULT_WSTETH_USDC, wstETH_ADDRESS, USDC_ADDRESS);
        closeVault(OLD_VAULT_WSTETH_USDT, wstETH_ADDRESS, USDT_ADDRESS);
    }

    /***********************************|
    |          Vault Helper             |
    |__________________________________*/

    function closeVault(
        address vault,
        address supplyToken,
        address borrowToken
    ) internal {
        // Set user supply config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserSupplyConfig[]
                memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

            configs_[0] = AdminModuleStructs.UserSupplyConfig({
                user: address(vault),
                token: supplyToken,
                mode: 1,
                expandPercent: 0,
                expandDuration: 1,
                baseWithdrawalLimit: supplyToken == wstETH_ADDRESS
                    ? 2 * 1e18
                    : 10 * 1e18 // 2 wstETH or 10 ETH
            });

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = AdminModuleStructs.UserBorrowConfig({
                user: vault,
                token: borrowToken,
                mode: 1,
                expandPercent: 0,
                expandDuration: 1,
                baseDebtCeiling: 10,
                maxDebtCeiling: 100
            });

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }
    }
}
