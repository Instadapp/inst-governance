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

interface IFluidVaultT1DeploymentLogic {
    function vaultT1(address supplyToken_, address borrowToken_) external;
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

interface IDSAV2 {
    function cast(
        string[] memory _targetNames,
        bytes[] memory _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32);

    function isAuth(address user) external view returns (bool);
}

contract PayloadIGP30 {
    uint256 public constant PROPOSAL_ID = 30;

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

    IDSAV2 public constant TREASURY = IDSAV2(0x28849D2b63fA8D361e5fc15cB8aBB13019884d09);

    IFluidLiquidityAdmin public constant LIQUIDITY =
        IFluidLiquidityAdmin(0x52Aa899454998Be5b000Ad077a46Bbe360F4e497);
    IFluidReserveContract public constant FLUID_RESERVE =
        IFluidReserveContract(0x264786EF916af64a1DB19F513F24a3681734ce92);
    IFluidVaultT1Factory public constant VAULT_T1_FACTORY =
        IFluidVaultT1Factory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);
    IFluidVaultT1DeploymentLogic public constant VAULT_T1_DEPLOYMENT_LOGIC =
        IFluidVaultT1DeploymentLogic(
            0x2Cc710218F2e3a82CcC77Cc4B3B93Ee6Ba9451CD
        );

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;

    address public constant wBTC_ADDRESS =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

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

        /// Action 1: Set wBTC token config and market rate curve on liquidity.
        action1();

        /// Action 2: Deploy wBTC/USDC and wBTC/USDT vaults.
        action2();

        /// Action 3: Deploy wBTC/ETH and ETH/wBTC vaults.
        action3();

        /// Action 4: Deploy wstETH/wBTC and weETH/wBTC vaults.
        action4();

        /// Action 5: Clone from old vault config to new vault
        action5();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Set wBTC token config and market rate curve on liquidity.
    function action1() internal {
        {
            AdminModuleStructs.RateDataV1Params[]
                memory params_ = new AdminModuleStructs.RateDataV1Params[](1);

            params_[0] = AdminModuleStructs.RateDataV1Params({
                token: wBTC_ADDRESS, // wBTC
                kink: 80 * 1e2, // 80%
                rateAtUtilizationZero: 0, // 0%
                rateAtUtilizationKink: 5 * 1e2, // 5%
                rateAtUtilizationMax: 100 * 1e2 // 100%
            });

            LIQUIDITY.updateRateDataV1s(params_);
        }

        {
            AdminModuleStructs.TokenConfig[]
                memory params_ = new AdminModuleStructs.TokenConfig[](1);

            params_[0] = AdminModuleStructs.TokenConfig({
                token: wBTC_ADDRESS, // wBTC
                threshold: 0.3 * 1e2, // 0.3
                fee: 10 * 1e2, // 10%
                maxUtilization: 100 * 1e2
            });

            LIQUIDITY.updateTokenConfigs(params_);
        }

    }

    /// @notice Action 2: Deploy wBTC/USDC and wBTC/USDT vaults.
    function action2() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            // user supply config for the vault on Liquidity Layer.
            supplyToken: wBTC_ADDRESS,
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M

            borrowToken: address(0),
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowMaxLimitInUSD: 200_000_000, // $200M

            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 80 * 1e2, // 80% 
            liquidationThreshold: 85 * 1e2, // 85% 
            liquidationMaxLimit: 90 * 1e2, // 90% 
            withdrawGap: 5 * 1e2, // 5% 
            liquidationPenalty: 0,
            borrowFee: 0 * 1e2, // 0% 

            oracle: address(0)
        });

        {
            vaultConfig.borrowToken = USDC_ADDRESS;

            vaultConfig.liquidationPenalty = 3 * 1e2; // 3% 

            vaultConfig.oracle = 0x131BA983Ab640Ce291B98694b3Def4288596cD09;

            // Deploy wBTC/USDC vault.
            address vault_ = deployVault(vaultConfig);

            // Set USDC rewards contract
            VAULT_T1_FACTORY.setVaultAuth(
                vault_,
                0xF561347c306E3Ccf213b73Ce2353D6ed79f92408,
                true
            );
        }

        {
            vaultConfig.borrowToken = USDT_ADDRESS;

            vaultConfig.liquidationPenalty = 4 * 1e2; // 4% 

            vaultConfig.oracle = 0xFF272430E88B3f804d9E30886677A36021864Cc4;

            // Deploy wBTC/USDT vault.
            address vault_ = deployVault(vaultConfig);

            // Set USDC rewards contract
            VAULT_T1_FACTORY.setVaultAuth(
                vault_,
                0x36C677a6AbDa7D6409fB74d1136A65aF1415F539,
                true
            );
        }
    }

    /// @notice Action 3: Deploy wBTC/ETH and ETH/wBTC vaults.
    function action3() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            // user supply config for the vault on Liquidity Layer.
            supplyToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M

            borrowToken: address(0),
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowMaxLimitInUSD: 200_000_000, // $200M

            supplyRateMagnifier: 100 * 1e2, // 1x
            borrowRateMagnifier: 100 * 1e2, // 1x
            collateralFactor: 90 * 1e2, // 90% 
            liquidationThreshold: 94 * 1e2, // 94% 
            liquidationMaxLimit: 96 * 1e2, // 96% 
            withdrawGap: 5 * 1e2, // 5% 
            liquidationPenalty: 2 * 1e2, // 2% 
            borrowFee: 0 * 1e2, // 0% 

            oracle: address(0)
        });

        // Deploy wBTC/ETH vault.
        {
            vaultConfig.supplyToken = wBTC_ADDRESS;
            vaultConfig.borrowToken = ETH_ADDRESS;

            vaultConfig.oracle = address(0x4C57Ef1012bDFFCe68FDDcD793Bb2b8B7D27DC06);

            deployVault(vaultConfig);
        }

        // Deploy ETH/wBTC vault.
        {
            vaultConfig.supplyToken = ETH_ADDRESS;
            vaultConfig.borrowToken = wBTC_ADDRESS;

            vaultConfig.oracle = address(0x63Ae926f97A480B18d58370268672766643f577F);

            deployVault(vaultConfig);
        }
    }

    /// @notice Action 4: Deploy wstETH/wBTC and weETH/wBTC vaults.
    function action4() internal {
        // wstETH/wBTC
        {
            VaultConfig memory vaultConfig = VaultConfig({
                // user supply config for the vault on Liquidity Layer.
                supplyToken: wstETH_ADDRESS,
                supplyMode: 1, // Mode 1
                supplyExpandPercent: 25 * 1e2, // 25%
                supplyExpandDuration: 12 hours, // 12 hours
                supplyBaseLimitInUSD: 5_000_000, // $5M

                borrowToken: wBTC_ADDRESS,
                borrowMode: 1, // Mode 1
                borrowExpandPercent: 20 * 1e2, // 20%
                borrowExpandDuration: 12 hours, // 12 hours
                borrowBaseLimitInUSD: 7_500_000, // $7.5M
                borrowMaxLimitInUSD: 200_000_000, // $200M

                supplyRateMagnifier: 100 * 1e2, // 1x
                borrowRateMagnifier: 100 * 1e2, // 1x
                collateralFactor: 88 * 1e2, // 88% 
                liquidationThreshold: 91 * 1e2, // 91% 
                liquidationMaxLimit: 94 * 1e2, // 94% 
                withdrawGap: 5 * 1e2, // 5% 
                liquidationPenalty: 2 * 1e2, // 2% 
                borrowFee: 0 * 1e2, // 0% 

                oracle: 0xD25c68bb507f8E19386F4F102462e1bfbfA7869F
            });

            // Deploy wstETH/wBTC
            deployVault(vaultConfig);
        }

        // weETH/wBTC
        {
            VaultConfig memory vaultConfig = VaultConfig({
                // user supply config for the vault on Liquidity Layer.
                supplyToken: weETH_ADDRESS,
                supplyMode: 1, // Mode 1
                supplyExpandPercent: 25 * 1e2, // 25%
                supplyExpandDuration: 12 hours, // 12 hours
                supplyBaseLimitInUSD: 5_000_000, // $5M

                borrowToken: wBTC_ADDRESS,
                borrowMode: 1, // Mode 1
                borrowExpandPercent: 20 * 1e2, // 20%
                borrowExpandDuration: 12 hours, // 12 hours
                borrowBaseLimitInUSD: 7_500_000, // $7.5M
                borrowMaxLimitInUSD: 20_000_000, // $20M

                supplyRateMagnifier: 100 * 1e2, // 1x
                borrowRateMagnifier: 100 * 1e2, // 1x
                collateralFactor: 80 * 1e2, // 80% 
                liquidationThreshold: 85 * 1e2, // 85% 
                liquidationMaxLimit: 90 * 1e2, // 90% 
                withdrawGap: 5 * 1e2, // 5% 
                liquidationPenalty: 5 * 1e2, // 5% 
                borrowFee: 0 * 1e2, // 0% 

                oracle: 0xBD7ea28840B120E2a2645F103273B0Dc23599E05
            });

            // Deploy weETH/wBTC
            deployVault(vaultConfig);
        }
    }

    /// @notice Action 5: Clone from old vault config to new vault
    function action5() internal {
        for (uint oldVaultId = 1; oldVaultId <= 10; oldVaultId++) {
            configNewVaultWithOldVaultConfigs(oldVaultId);
        }
    }

    /// @notice Action 6: call cast() - transfer 2 wBTC to Fluid Reserve contract from treasury.
    function action6() internal {
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer wBTC
        {   
            uint256 wBTC_AMOUNT = 2 * 1e8; // 2 wBTC
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(withdrawSignature, wBTC_ADDRESS, wBTC_AMOUNT, FLUID_RESERVE, 0, 0);
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    /***********************************|
    |     Proposal Payload Helpers      |
    |__________________________________*/

    struct VaultConfig {
        address supplyToken;
        uint8 supplyMode;
        uint256 supplyExpandPercent;
        uint256 supplyExpandDuration;
        uint256 supplyBaseLimitInUSD;

        address borrowToken;
        uint8 borrowMode;
        uint256 borrowExpandPercent;
        uint256 borrowExpandDuration;
        uint256 borrowBaseLimitInUSD;
        uint256 borrowMaxLimitInUSD;

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

    function deployVault(VaultConfig memory vaultConfig) internal returns (address vault_) {
        // Deploy vault.
        vault_ = VAULT_T1_FACTORY.deployVault(
            address(VAULT_T1_DEPLOYMENT_LOGIC),
            abi.encodeWithSelector(
                IFluidVaultT1DeploymentLogic.vaultT1.selector,
                vaultConfig.supplyToken,
                vaultConfig.borrowToken 
            )
        );

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
                expandPercent: vaultConfig.supplyExpandPercent,
                expandDuration: vaultConfig.borrowExpandDuration,
                baseDebtCeiling: getRawAmount(
                    vaultConfig.borrowToken,
                    vaultConfig.borrowBaseLimitInUSD,
                    false
                ),
                maxDebtCeiling: getRawAmount(
                    vaultConfig.borrowToken,
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
            IFluidVaultT1(vault_).updateRebalancer(
                0x264786EF916af64a1DB19F513F24a3681734ce92
            );
        }
    }

    function getUserSupplyData(
        address token_,
        address oldVault_,
        address newVault_
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
        config_ = AdminModuleStructs.UserSupplyConfig({
            user: newVault_,
            token: token_,
            mode: uint8(userSupplyData_ & 1),
            expandPercent: (userSupplyData_ >>
                LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_PERCENT) & X14,
            expandDuration: (userSupplyData_ >>
                LiquiditySlotsLink.BITS_USER_SUPPLY_EXPAND_DURATION) & X24,
            baseWithdrawalLimit: 
                BigMathMinified.fromBigNumber(
                    (userSupplyData_ >> LiquiditySlotsLink.BITS_USER_SUPPLY_BASE_WITHDRAWAL_LIMIT) & X18,
                    DEFAULT_EXPONENT_SIZE,
                    DEFAULT_EXPONENT_MASK
                )
        });
    }

    function getUserBorrowData(
        address token_,
        address oldVault_,
        address newVault_
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

        config_ = AdminModuleStructs.UserBorrowConfig({
            user: newVault_,
            token: token_,
            mode: uint8(userBorrowData_ & 1),
            expandPercent: (userBorrowData_ >>
                LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_PERCENT) & X14,
            expandDuration: (userBorrowData_ >>
                LiquiditySlotsLink.BITS_USER_BORROW_EXPAND_DURATION) & X24,
            baseDebtCeiling: 
                BigMathMinified.fromBigNumber(
                    (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_BASE_BORROW_LIMIT) & X18,
                    DEFAULT_EXPONENT_SIZE,
                    DEFAULT_EXPONENT_MASK
                ),
            maxDebtCeiling: 
                BigMathMinified.fromBigNumber(
                    (userBorrowData_ >> LiquiditySlotsLink.BITS_USER_BORROW_MAX_BORROW_LIMIT) & X18,
                    DEFAULT_EXPONENT_SIZE,
                    DEFAULT_EXPONENT_MASK
                )
        });
    }

    struct CloneVaultStruct {
        address oldVaultAddress;
        address newVaultAddress;
    }

    function configNewVaultWithOldVaultConfigs(uint256 oldVaultId) internal {
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

            configs_[0] = getUserSupplyData(
                newConstants.supplyToken,
                data.oldVaultAddress,
                data.newVaultAddress
            );

            LIQUIDITY.updateUserSupplyConfigs(configs_);
        }

        // Set user borrow config for the vault on Liquidity Layer.
        {
            AdminModuleStructs.UserBorrowConfig[]
                memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

            configs_[0] = getUserBorrowData(
                newConstants.borrowToken,
                data.oldVaultAddress,
                data.newVaultAddress
            );

            LIQUIDITY.updateUserBorrowConfigs(configs_);
        }
    }

    function getRawAmount(address token, uint256 amountInUSD, bool isSupply) public view returns(uint256){
        uint256 exchangePriceAndConfig_ = 
            LIQUIDITY.readFromStorage(
                LiquiditySlotsLink.calculateMappingStorageSlot(
                    LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT,
                    token
                )
            );

        (uint256 supplyExchangePrice, uint256 borrowExchangePrice) = LiquidityCalcs.calcExchangePrices(exchangePriceAndConfig_);

        uint256 usdPrice = 0;
        uint256 decimals = 18;
        if (token == wBTC_ADDRESS) {
            usdPrice = 61_000;
            decimals = 8;
        } else if (token == ETH_ADDRESS) {
            usdPrice = 3_400;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = 4_000;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = 3_550;
            decimals = 18;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = 1;
            decimals = 6;
        } else {
            revert("not-found");
        }

        uint256 exchangePrice = isSupply ? supplyExchangePrice : borrowExchangePrice;
        return (amountInUSD * 1e12 * (10 ** decimals)) / (usdPrice * exchangePrice);
    }
}
