pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { BigMathMinified } from "./libraries/bigMathMinified.sol";
import { LiquiditySlotsLink } from "./libraries/liquiditySlotsLink.sol";

interface IGovernorBravo {
    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint);

    function admin() external view returns (address);

    function timelock() external view returns (address);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);
}

interface ITimelock {
    function admin() external view returns (address);
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

    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
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
    function updateSupplyRateMagnifier(uint supplyRateMagnifier_) external;
}

contract PayloadIGP12 {
    uint256 public constant PROPOSAL_ID = 12;

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
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WSTETH_ADDRESS = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant VAULT_ETH_USDC = address(0xeAbBfca72F8a8bf14C4ac59e69ECB2eB69F0811C);
    address public constant VAULT_ETH_USDT = address(0xbEC491FeF7B4f666b270F9D5E5C3f443cBf20991);
    address public constant VAULT_WSTETH_ETH = address(0xA0F83Fc5885cEBc0420ce7C7b139Adc80c4F4D91);
    address public constant VAULT_WSTETH_USDC = address(0x51197586F6A9e2571868b6ffaef308f3bdfEd3aE);
    address public constant VAULT_WSTETH_USDT = address(0x1c2bB46f36561bc4F05A94BD50916496aa501078);
    
    uint256 internal constant X14 = 0x3fff;
    uint256 internal constant X18 = 0x3ffff;
    uint256 internal constant X24 = 0xffffff;
    uint256 internal constant X64 = 0xffffffffffffffff;

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

        // Action 1: Update supply expand percent to 20% for fUSDT on liquidity. 
        action1();

        // Action 2: Update supply expand percent to 20% for fUSDC on liquidity. 
        action2();

        // Action 3: Update supply expand percent to 20% for fWETH on liquidity. 
        action3();

        // Action 4: Update supply expand percent to 25% and borrow expand percent to 20% for ETH/USDC vault on liquidity.
        action4();

        // Action 5: Update supply expand percent to 25% and borrow expand percent to 20% for ETH/USDT vault on liquidity.
        action5();

        // Action 6: Update supply expand percent to 25% and borrow expand percent to 20% for WSTETH/ETH vault on liquidity.
        action6();

        // Action 7: Update supply expand percent to 25% and borrow expand percent to 20% for WSTETH/USDC vault on liquidity.
        action7();

        // Action 8: Update supply expand percent to 25% and borrow expand percent to 20% for WSTETH/USDT vault on liquidity.
        action8();

        // @notice Action 9: Remove config handlers for vaults and lending tokens on liquidity. 
        action9();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update supply expand percent to 20% for fUSDT on liquidity. 
    function action1() internal {
        address fUSDT = 0x5C20B550819128074FD538Edf79791733ccEdd18;

        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            USDT_ADDRESS,
            fUSDT
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }

    /// @notice Action 2: Update supply expand percent to 20% for fUSDC on liquidity. 
    function action2() internal {
        address fUSDC = address(0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33);

        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            USDC_ADDRESS,
            fUSDC
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }

    /// @notice Action 3: Update supply expand percent to 20% for fWETH on liquidity. 
    function action3() internal {
        address fWETH = address(0x90551c1795392094FE6D29B758EcCD233cFAa260);

        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            WETH_ADDRESS,
            fWETH
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }


    /// @notice Action 4: Update supply expand percent to 25% and borrow expand percent to 20% for ETH/USDC vault on liquidity. 
    function action4() internal {
        address user_ = VAULT_ETH_USDC;
        address supplyToken_ = ETH_ADDRESS;
        address borrowToken_ = USDC_ADDRESS;

        // Supply expand percent to 25%
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            supplyToken_,
            user_
        );

        configs_[0].expandPercent = 25 * 1e2; // 25%

        LIQUIDITY.updateUserSupplyConfigs(configs_);

        // Borrow expand percent to 20%
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[]();
        configs_[0] = getUserBorrowData(
            borrowToken_,
            user_
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 5: Update supply expand percent to 25% and borrow expand percent to 20% for ETH/USDT vault on liquidity. 
    function action5() internal {
        address user_ = VAULT_ETH_USDT;
        address supplyToken_ = ETH_ADDRESS;
        address borrowToken_ = USDT_ADDRESS;

        // Supply expand percent to 25%
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            supplyToken_,
            user_
        );

        configs_[0].expandPercent = 25 * 1e2; // 25%

        LIQUIDITY.updateUserSupplyConfigs(configs_);

        // Borrow expand percent to 20%
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[]();
        configs_[0] = getUserBorrowData(
            borrowToken_,
            user_
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 6: Update supply expand percent to 25% and borrow expand percent to 20% for wstETH/ETH vault on liquidity. 
    function action6() internal {
        address user_ = VAUTH_WSTETH_ETH;
        address supplyToken_ = WSTETH_ADDRESS;
        address borrowToken_ = ETH_ADDRESS;

        // Supply expand percent to 25%
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            supplyToken_,
            user_
        );

        configs_[0].expandPercent = 25 * 1e2; // 25%

        LIQUIDITY.updateUserSupplyConfigs(configs_);

        // Borrow expand percent to 20%
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[]();
        configs_[0] = getUserBorrowData(
            borrowToken_,
            user_
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 7: Update supply expand percent to 25% and borrow expand percent to 20% for wstETH/USDC vault on liquidity. 
    function action7() internal {
        address user_ = VAULT_WSTETH_USDC;
        address supplyToken_ = WSTETH_ADDRESS;
        address borrowToken_ = USDC_ADDRESS;

        // Supply expand percent to 25%
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            supplyToken_,
            user_
        );

        configs_[0].expandPercent = 25 * 1e2; // 25%

        LIQUIDITY.updateUserSupplyConfigs(configs_);

        // Borrow expand percent to 20%
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[]();
        configs_[0] = getUserBorrowData(
            borrowToken_,
            user_
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }


    /// @notice Action 8: Update supply expand percent to 25% and borrow expand percent to 20% for WSTETH/USDT vault on liquidity. 
    function action8() internal {
        address user_ = VAULT_WSTETH_USDC;
        address supplyToken_ = WSTETH_ADDRESS;
        address borrowToken_ = USDT_ADDRESS;

        // Supply expand percent to 25%
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[]();
        configs_[0] = getUserSupplyData(
            supplyToken_,
            user_
        );

        configs_[0].expandPercent = 25 * 1e2; // 25%

        LIQUIDITY.updateUserSupplyConfigs(configs_);

        // Borrow expand percent to 20%
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[]();
        configs_[0] = getUserBorrowData(
            borrowToken_,
            user_
        );

        configs_[0].expandPercent = 20 * 1e2; // 20%

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    /// @notice Action 9: Remove config handlers for vaults and lending tokens on liquidity. 
    function action9() internal {
        AdminModuleStructs.AddressBool[] memory addrBools_ = new AdminModuleStructs.AddressBool[](8);


        // fToken_fUSDC_LiquidityConfigHandler
        addrBools_[0] = AdminModuleStructs.AddressBool({
            addr: 0x02AfbFA971299c2434E7a04565d9f5a1eD6180F1,
            value: false
        })

        // fToken_fUSDT_LiquidityConfigHandler
        addrBools_[1] = AdminModuleStructs.AddressBool({
            addr: 0xF45364EC2230c64B1AB0cE1E4c7E63F0a2078F30,
            value: false
        })

        // fToken_fWETH_LiquidityConfigHandler
        addrBools_[2] = AdminModuleStructs.AddressBool({
            addr: 0x580f8C04080347F5675CF67C1E90d935463148dC,
            value: false
        })

        // Vault_ETH_USDC_LiquidityConfigHandler
        addrBools_[3] = AdminModuleStructs.AddressBool({
            addr: 0xacdf9C61720A4D97Afa7f215ddDD56C2d1019FC9,
            value: false
        })

        // Vault_ETH_USDT_LiquidityConfigHandler
        addrBools_[4] = AdminModuleStructs.AddressBool({
            addr: 0x2274F61847703DBA28300BD7a0Fb3f1166Cb0E7C,
            value: false
        })

        // Vault_wstETH_ETH_LiquidityConfigHandler
        addrBools_[5] = AdminModuleStructs.AddressBool({
            addr: 0x28D64d5c85E9a0f0a33A481E71842255aeFf0Fe9,
            value: false
        })

        // Vault_wstETH_USDC_LiquidityConfigHandler
        addrBools_[6] = AdminModuleStructs.AddressBool({
            addr: 0xa66906140D5d413E40b1AE452B52DD1f162D47cA,
            value: false
        })

        // Vault_wstETH_USDT_LiquidityConfigHandler
        addrBools_[7] = AdminModuleStructs.AddressBool({
            addr: 0xB7AE8D080c7C26152e43DD6e8dcA7451BB33Be68,
            value: false
        })

        LIQUIDITY.updateAuths(addrBools_);
    }




    /***********************************|
    |     Proposal Payload Helpers      |
    |__________________________________*/

    function getUserSupplyData(address token_, address user_) internal returns(AdminModuleStructs.UserSupplyConfig memory config_) {
        bytes32 _LIQUDITY_PROTOCOL_SUPPLY_SLOT = LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
            LiquiditySlotsLink.LIQUIDITY_USER_SUPPLY_DOUBLE_MAPPING_SLOT,
            user_,
            token_
        );

        bytes32 userSupplyData_ = LIQUIDITY.readFromStorage(_LIQUDITY_PROTOCOL_SUPPLY_SLOT); 

        config_ = AdminModuleStructs.UserSupplyConfig({
            user: user_,
            token: token_,
            mode: uint8(userSupplyData_ & 1),
            expandPercent: (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_PERCENT) & X14,
            expandDuration: (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_DURATION) & X24,
            baseWithdrawalLimit: BigMathMinified.fromBigNumber(
                (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });
    }

    function getUserBorrowData(address token_, address user_) internal returns(AdminModuleStructs.UserBorrowConfig memory config_) {
        bytes32 _LIQUDITY_PROTOCOL_BORROW_SLOT = LiquiditySlotsLink.calculateDoubleMappingStorageSlot(
            LiquiditySlotsLink.LIQUIDITY_USER_BORROW_DOUBLE_MAPPING_SLOT,
            user_,
            token_
        );

        userBorrowData_ = LIQUIDITY.readFromStorage(_LIQUDITY_PROTOCOL_BORROW_SLOT);

        config_ = AdminModuleStructs.UserBorrowConfig({
            user: user_,
            token: token_,
            mode: uint8(userBorrowData_ & 1),
            expandPercent: (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_PERCENT) & X14;,
            expandDuration: (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_DURATION) & X24,
            baseDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            ),
            maxDebtCeiling: BigMathMinified.fromBigNumber(
                (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18,
                DEFAULT_EXPONENT_SIZE,
                DEFAULT_EXPONENT_MASK
            )
        });
    }
}
