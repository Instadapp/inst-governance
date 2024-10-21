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

interface FluidDexFactory {
    /// @notice                         Computes the address of a dex based on its given ID (`dexId_`).
    /// @param dexId_                   The ID of the dex.
    /// @return dex_                    Returns the computed address of the dex.
    function getDexAddress(uint256 dexId_) external view returns (address dex_);
}

contract PayloadIGP45 {
    uint256 public constant PROPOSAL_ID = 45;

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

    FluidVaultFactory public constant VAULT_FACTORY =
        FluidVaultFactory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);
    FluidDexFactory public constant OLD_DEX_FACTORY =
        FluidDexFactory(0xF9b539Cd37Fc81bBEA1F078240d16b988BBae073);

    FluidDexFactory public constant NEW_DEX_FACTORY =
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

        // Action 1: Set supply and borrow limit for old Dexes on Liquidity Layer
        action1();

        // Action 2: Set old Vault limits on liquidity layer and auth on vaultFactory
        action2();

        // Action 3: Set supply and borrow limit for new Dexes on Liquidity Layer
        action3();

        // Action 2: Set new Vault limits on liquidity layer and auth on vaultFactory
        action4();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Set supply and borrow limit for Old Dexes on Liquidity Layer
    function action1() internal {
        Dex memory DEX_wstETH_ETH = Dex({
            dex: getOldDexAddress(1),
            tokenA: wstETH_ADDRESS,
            tokenB: ETH_ADDRESS,
            smartCollateral: true,
            smartDebt: true
        });
        removeDexLimits(DEX_wstETH_ETH); // Smart Collateral & Smart Debt

        Dex memory DEX_USDC_USDT = Dex({
            dex: getOldDexAddress(2),
            tokenA: USDC_ADDRESS,
            tokenB: USDT_ADDRESS,
            smartCollateral: false,
            smartDebt: true
        });
        removeDexLimits(DEX_USDC_USDT); // Smart Debt

        Dex memory DEX_cbBTC_WBTC = Dex({
            dex: getOldDexAddress(3),
            tokenA: cbBTC_ADDRESS,
            tokenB: WBTC_ADDRESS,
            smartCollateral: true,
            smartDebt: true
        });
        removeDexLimits(DEX_cbBTC_WBTC); // Smart Collateral & Smart Debt
    }

    /// @notice Action 2: Set Vault limits on liquidity layer and auth on vaultFactory
    function action2() internal {
        {
            // [TYPE 4] wstETH-ETH  | wstETH-ETH | Smart collateral & smart debt
            Vault memory VAULT_wstETH_ETH_AND_wsETH_ETH = Vault({
                vault: getVaultAddress(34),
                vaultType: TYPE.TYPE_4,
                supplyToken: address(0),
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_wstETH_ETH_AND_wsETH_ETH); // TYPE_4 => 34
        }

        {
            // [TYPE 3] ETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_ETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(35),
                vaultType: TYPE.TYPE_3,
                supplyToken: ETH_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_ETH_AND_USDC_USDT); // TYPE_3 => 35
        }

        {
            // [TYPE 3] wstETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_wstETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(36),
                vaultType: TYPE.TYPE_3,
                supplyToken: wstETH_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_wstETH_AND_USDC_USDT); // TYPE_3 => 36
        }

        {
            // [TYPE 3] weETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_weETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(37),
                vaultType: TYPE.TYPE_3,
                supplyToken: weETH_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_weETH_AND_USDC_USDT); // TYPE_3 => 37
        }

        {
            // [TYPE 3] WBTC | USDC-USDT | Smart Debt only
            Vault memory VAULT_WBTC_AND_USDC_USDT = Vault({
                vault: getVaultAddress(38),
                vaultType: TYPE.TYPE_3,
                supplyToken: WBTC_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_WBTC_AND_USDC_USDT); // TYPE_3 => 38
        }

        {
            // [TYPE 3] cbBTC | USDC-USDT | Smart Debt only
            Vault memory VAULT_cbBTC_AND_USDC_USDT = Vault({
                vault: getVaultAddress(39),
                vaultType: TYPE.TYPE_3,
                supplyToken: cbBTC_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_cbBTC_AND_USDC_USDT); // TYPE_3 => 39
        }

        {
            // [TYPE 3] sUSDe | USDC-USDT | Smart Debt only
            Vault memory VAULT_sUSDe_AND_USDC_USDT = Vault({
                vault: getVaultAddress(40),
                vaultType: TYPE.TYPE_3,
                supplyToken: sUSDe_ADDRESS,
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_sUSDe_AND_USDC_USDT); // TYPE_3 => 40
        }

        {
            // [TYPE 4] cbBTC-WBTC | cbBTC-WBTC | Smart collateral & smart debt
            Vault memory VAULT_cbBTC_WBTC_AND_cbBTC_WBTC = Vault({
                vault: getVaultAddress(41),
                vaultType: TYPE.TYPE_4,
                supplyToken: address(0),
                borrowToken: address(0)
            });
            removeVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_cbBTC_WBTC); // TYPE_4 => 41
        }

        {
            // [TYPE 2] cbBTC-WBTC | USDC | Smart Collateral only
            Vault memory VAULT_cbBTC_WBTC_AND_USDC = Vault({
                vault: getVaultAddress(42),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDC_ADDRESS
            });
            removeVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_USDC); // TYPE_2 => 42
        }

        {
            // [TYPE 2] cbBTC-WBTC | USDT | Smart Collateral only
            Vault memory VAULT_cbBTC_WBTC_AND_USDT = Vault({
                vault: getVaultAddress(43),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS
            });
            removeVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_USDT); // TYPE_2 => 43
        }
    }

    /// @notice Action 3: Set supply and borrow limit for New Dexes on Liquidity Layer
    function action3() internal {
        Dex memory DEX_wstETH_ETH = Dex({
            dex: getNewDexAddress(1),
            tokenA: wstETH_ADDRESS,
            tokenB: ETH_ADDRESS,
            smartCollateral: true,
            smartDebt: true
        });
        setDexLimits(DEX_wstETH_ETH); // Smart Collateral & Smart Debt

        Dex memory DEX_USDC_USDT = Dex({
            dex: getNewDexAddress(2),
            tokenA: USDC_ADDRESS,
            tokenB: USDT_ADDRESS,
            smartCollateral: false,
            smartDebt: true
        });
        setDexLimits(DEX_USDC_USDT); // Smart Debt

        Dex memory DEX_cbBTC_WBTC = Dex({
            dex: getNewDexAddress(3),
            tokenA: cbBTC_ADDRESS,
            tokenB: WBTC_ADDRESS,
            smartCollateral: true,
            smartDebt: true
        });
        setDexLimits(DEX_cbBTC_WBTC); // Smart Collateral & Smart Debt
    }

    /// @notice Action 4: Set Vault limits on liquidity layer and auth on vaultFactory
    function action4() internal {
        {
            // [TYPE 4] wstETH-ETH  | wstETH-ETH | Smart collateral & smart debt
            Vault memory VAULT_wstETH_ETH_AND_wsETH_ETH = Vault({
                vault: getVaultAddress(44),
                vaultType: TYPE.TYPE_4,
                supplyToken: address(0),
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_wstETH_ETH_AND_wsETH_ETH); // TYPE_4 => 44
        }

        {
            // [TYPE 3] ETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_ETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(45),
                vaultType: TYPE.TYPE_3,
                supplyToken: ETH_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_ETH_AND_USDC_USDT); // TYPE_3 => 45
        }

        {
            // [TYPE 3] wstETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_wstETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(46),
                vaultType: TYPE.TYPE_3,
                supplyToken: wstETH_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_wstETH_AND_USDC_USDT); // TYPE_3 => 46
        }

        {
            // [TYPE 3] weETH | USDC-USDT | Smart Debt only
            Vault memory VAULT_weETH_AND_USDC_USDT = Vault({
                vault: getVaultAddress(47),
                vaultType: TYPE.TYPE_3,
                supplyToken: weETH_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_weETH_AND_USDC_USDT); // TYPE_3 => 47
        }

        {
            // [TYPE 3] WBTC | USDC-USDT | Smart Debt only
            Vault memory VAULT_WBTC_AND_USDC_USDT = Vault({
                vault: getVaultAddress(48),
                vaultType: TYPE.TYPE_3,
                supplyToken: WBTC_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_WBTC_AND_USDC_USDT); // TYPE_3 => 48
        }

        {
            // [TYPE 3] cbBTC | USDC-USDT | Smart Debt only
            Vault memory VAULT_cbBTC_AND_USDC_USDT = Vault({
                vault: getVaultAddress(49),
                vaultType: TYPE.TYPE_3,
                supplyToken: cbBTC_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_cbBTC_AND_USDC_USDT); // TYPE_3 => 49
        }

        {
            // [TYPE 3] sUSDe | USDC-USDT | Smart Debt only
            Vault memory VAULT_sUSDe_AND_USDC_USDT = Vault({
                vault: getVaultAddress(50),
                vaultType: TYPE.TYPE_3,
                supplyToken: sUSDe_ADDRESS,
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_sUSDe_AND_USDC_USDT); // TYPE_3 => 50
        }

        {
            // [TYPE 4] cbBTC-WBTC | cbBTC-WBTC | Smart collateral & smart debt
            Vault memory VAULT_cbBTC_WBTC_AND_cbBTC_WBTC = Vault({
                vault: getVaultAddress(51),
                vaultType: TYPE.TYPE_4,
                supplyToken: address(0),
                borrowToken: address(0)
            });
            setVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_cbBTC_WBTC); // TYPE_4 => 51
        }

        {
            // [TYPE 2] cbBTC-WBTC | USDC | Smart Collateral only
            Vault memory VAULT_cbBTC_WBTC_AND_USDC = Vault({
                vault: getVaultAddress(52),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDC_ADDRESS
            });
            setVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_USDC); // TYPE_2 => 52
        }

        {
            // [TYPE 2] cbBTC-WBTC | USDT | Smart Collateral only
            Vault memory VAULT_cbBTC_WBTC_AND_USDT = Vault({
                vault: getVaultAddress(43),
                vaultType: TYPE.TYPE_2,
                supplyToken: address(0),
                borrowToken: USDT_ADDRESS
            });
            setVaultLimitsAndAuth(VAULT_cbBTC_WBTC_AND_USDT); // TYPE_2 => 53
        }
    }



    /***********************************|
    |     Proposal Payload Helpers      |
    |__________________________________*/

    function getVaultAddress(uint256 vaultId_) public view returns (address) {
        return VAULT_FACTORY.getVaultAddress(vaultId_);
    }

    function getOldDexAddress(uint256 dexId_) public view returns (address) {
        return OLD_DEX_FACTORY.getDexAddress(dexId_);
    }

    function getNewDexAddress(uint256 dexId_) public view returns (address) {
        return NEW_DEX_FACTORY.getDexAddress(dexId_);
    }

    function removeDexLimits(Dex memory dex_) internal {
        // Smart Collateral
        if (dex_.smartCollateral) {
            SupplyProtocolConfig memory protocolConfigTokenA_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenA,
                baseWithdrawalLimitInUSD: 0
            });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenB,
                baseWithdrawalLimitInUSD: 0
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);
        }

        // Smart Debt
        if (dex_.smartDebt) {
            BorrowProtocolConfig memory protocolConfigTokenA_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenA,
                baseBorrowLimitInUSD: 0,
                maxBorrowLimitInUSD: 0
            });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig memory protocolConfigTokenB_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenB,
                baseBorrowLimitInUSD: 0,
                maxBorrowLimitInUSD: 0
            });

            setBorrowProtocolLimits(protocolConfigTokenB_);
        }
    }

    function setDexLimits(Dex memory dex_) internal {
        // Smart Collateral
        if (dex_.smartCollateral) {
            SupplyProtocolConfig memory protocolConfigTokenA_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenA,
                baseWithdrawalLimitInUSD: 50_000 // $50k
            });

            setSupplyProtocolLimits(protocolConfigTokenA_);

            SupplyProtocolConfig memory protocolConfigTokenB_ = SupplyProtocolConfig({
                protocol: dex_.dex,
                supplyToken: dex_.tokenB,
                baseWithdrawalLimitInUSD: 50_000 // $50k
            });

            setSupplyProtocolLimits(protocolConfigTokenB_);
        }

        // Smart Debt
        if (dex_.smartDebt) {
            BorrowProtocolConfig memory protocolConfigTokenA_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenA,
                baseBorrowLimitInUSD: 40_000, // $40k
                maxBorrowLimitInUSD: 50_000 // $50k
            });

            setBorrowProtocolLimits(protocolConfigTokenA_);

            BorrowProtocolConfig memory protocolConfigTokenB_ = BorrowProtocolConfig({
                protocol: dex_.dex,
                borrowToken: dex_.tokenB,
                baseBorrowLimitInUSD: 40_000, // $40k
                maxBorrowLimitInUSD: 50_000 // $50k
            });

            setBorrowProtocolLimits(protocolConfigTokenB_);
        }
    }

    function removeVaultLimitsAndAuth(Vault memory vault_) internal {
        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                baseWithdrawalLimitInUSD: 0
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                baseBorrowLimitInUSD: 0,
                maxBorrowLimitInUSD: 0
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        VAULT_FACTORY.setVaultAuth(vault_.vault, TEAM_MULTISIG, false);
    }

    function setVaultLimitsAndAuth(Vault memory vault_) internal {
        if (vault_.vaultType == TYPE.TYPE_3) {
            SupplyProtocolConfig memory protocolConfig_ = SupplyProtocolConfig({
                protocol: vault_.vault,
                supplyToken: vault_.supplyToken,
                baseWithdrawalLimitInUSD: 40_000 // $40k
            });

            setSupplyProtocolLimits(protocolConfig_);
        }

        if (vault_.vaultType == TYPE.TYPE_2) {
            BorrowProtocolConfig memory protocolConfig_ = BorrowProtocolConfig({
                protocol: vault_.vault,
                borrowToken: vault_.borrowToken,
                baseBorrowLimitInUSD: 20_000, // $20k
                maxBorrowLimitInUSD: 25_000 // $25k
            });

            setBorrowProtocolLimits(protocolConfig_);
        }

        VAULT_FACTORY.setVaultAuth(vault_.vault, TEAM_MULTISIG, true);
    }

    struct SupplyProtocolConfig {
        address protocol;
        address supplyToken;
        uint256 baseWithdrawalLimitInUSD;
    }
    struct BorrowProtocolConfig {
        address protocol;
        address borrowToken;
        uint256 baseBorrowLimitInUSD;
        uint256 maxBorrowLimitInUSD;
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
                expandPercent: 25 * 1e2,
                expandDuration: 12 hours,
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
                expandPercent: 20 * 1e2,
                expandDuration: 12 hours,
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
            usdPrice = 2_450 * 1e2;
            decimals = 18;
        } else if (token == wstETH_ADDRESS) {
            usdPrice = 2_900 * 1e2;
            decimals = 18;
        } else if (token == weETH_ADDRESS) {
            usdPrice = 2_570 * 1e2;
            decimals = 18;
        } else if (token == cbBTC_ADDRESS || token == WBTC_ADDRESS) {
            usdPrice = 62_500 * 1e2;
            decimals = 8;
        } else if (token == USDC_ADDRESS || token == USDT_ADDRESS) {
            usdPrice = 1 * 1e2;
            decimals = 6;
        } else if (token == sUSDe_ADDRESS) {
            usdPrice = 1.1 * 1e2;
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
