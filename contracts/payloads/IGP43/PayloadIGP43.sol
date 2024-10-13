pragma solidity ^0.8.21;
pragma experimental ABIEncoderV2;

import {LiquiditySlotsLink} from "./libraries/liquiditySlotsLink.sol";
import {LiquidityCalcs} from "./libraries/liquidityCalcs.sol";

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

    function readFromStorage(
        bytes32 slot_
    ) external view returns (uint256 result_);
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
    function getPool(uint256 poolId_) external view returns (Pool memory pool_);
}

interface FluidVaultFactory {
    /// @notice                         Sets an address as allowed vault deployment logic (`deploymentLogic_`) contract or not.
    ///                                 This function can only be called by the owner.
    /// @param deploymentLogic_         The address of the vault deployment logic contract to be set.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to deploy new type of vault.
    function setVaultDeploymentLogic(address deploymentLogic_, bool allowed_) external;

    /// @notice                         Sets an address (`vaultAuth_`) as allowed vault authorization or not for a specific vault (`vault_`).
    ///                                 This function can only be called by the owner.
    /// @param vault_                   The address of the vault for which the authorization is being set.
    /// @param vaultAuth_               The address to be set as vault authorization.
    /// @param allowed_                 A boolean indicating whether the specified address is allowed to update the specific vault config.
    function setVaultAuth(address vault_, address vaultAuth_, bool allowed_) external;
}

interface FluidVault {
    
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

    function constantsView() external view returns (ConstantViews memory constantsView_);
}

contract PayloadIGP43 {
    struct VaultConfig {
        uint256 vaultId;
        address supplyToken;
        address borrowToken;
        uint8 supplyMode;
        uint256 supplyExpandPercent;
        uint256 supplyExpandDuration;
        uint256 supplyBaseLimitInUSD;
        uint256 supplyBaseLimit;
        uint8 borrowMode;
        uint256 borrowExpandPercent;
        uint256 borrowExpandDuration;
        uint256 borrowBaseLimitInUSD;
        uint256 borrowBaseLimit;
        uint256 borrowMaxLimitInUSD;
        uint256 borrowMaxLimit;
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

    FluidDexReservesResolver public constant DEX_RESERVES_RESOLVER = FluidDexReservesResolver(0x278166A9B88f166EB170d55801bE1b1d1E576330);

    FluidVaultFactory public constant VAULT_FACTORY = FluidVaultFactory(0x324c5Dc1fC42c7a4D43d92df1eBA58a54d13Bf2d);

    address internal constant wstETH_ADDRESS = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant weETH_ADDRESS = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address internal constant cbBTC_ADDRESS = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;


    uint256 public constant wstETH_ETH_Dex = 1; // TODO add address here
    uint256 public constant USDC_USDT_Dex; // TODO add address here
    uint256 public constant cbBTC_WBTC_Dex; // TODO add address here

    address public constant wstETH_ETH_SMART_COL_DEBT; // TODO add address here
    address public constant ETH_USDC_USDT; // TODO add address here
    address public constant wstETH_USDC_USDT; // TODO add address here
    address public constant weETH_USDC_USDT; // TODO add address here
    address public constant WBTC_USDC_USDT; // TODO add address here
    address public constant cbBTC_USDC_USDT; // TODO add address here
    address public constant sUSDe_USDC_USDT; // TODO add address here
    address public constant cbBTC_WBTC_SMART_COL_DEBT; // TODO add address here
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
        // action1();  // TODO

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
    function action1(TokenConfig memory token0Config_, TokenConfig memory token1Config_) internal {
        FluidDexReservesResolver.Pool memory pool1_ = DEX_RESERVES_RESOLVER.getPool(wstETH_ETH_Dex);
        setSupplyConfigforDex(
            pool1_.pool, pool1_.token0, pool1_.token1, token0Config_, token1Config_
        );
        setBorrowConfigforDex(
            pool1_.pool, pool1_.token0, pool1_.token1, token0Config_, token1Config_
        );

        FluidDexReservesResolver.Pool memory pool2_ = DEX_RESERVES_RESOLVER.getPool(USDC_USDT_Dex);
        setBorrowConfigforDex(
            pool2_.pool, pool2_.token0, pool2_.token1, token0Config_, token1Config_
        );

        FluidDexReservesResolver.Pool memory pool3_ = DEX_RESERVES_RESOLVER.getPool(cbBTC_WBTC_Dex);
        setSupplyConfigforDex(
            pool3_.pool, pool3_.token0, pool3_.token1, token0Config_, token1Config_
        );
        setBorrowConfigforDex(
            pool3_.pool, pool3_.token0, pool3_.token1, token0Config_, token1Config_
        );
    }

    /// @notice Action 2: Setting team multisig as vault auth in 10 vaults
    function action2() internal {
        VAULT_FACTORY.setVaultAuth(wstETH_ETH_SMART_COL_DEBT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(ETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(wstETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(weETH_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(WBTC_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(sUSDe_USDC_USDT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_SMART_COL_DEBT, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_USDC, TEAM_MULTISIG, true);
        VAULT_FACTORY.setVaultAuth(cbBTC_WBTC_USDT, TEAM_MULTISIG, true);
    }

    /// @notice Action 3: Setting the vault limits
    function action3() internal {
        VaultConfig memory vaultConfig = VaultConfig({
            vaultId: 0,
            supplyToken: address(0),
            borrowToken: address(0),
            supplyMode: 1, // Mode 1
            supplyExpandPercent: 25 * 1e2, // 25%
            supplyExpandDuration: 12 hours, // 12 hours
            supplyBaseLimitInUSD: 5_000_000, // $5M
            supplyBaseLimit: 0,
            borrowMode: 1, // Mode 1
            borrowExpandPercent: 20 * 1e2, // 20%
            borrowExpandDuration: 12 hours, // 12 hours
            borrowBaseLimitInUSD: 7_500_000, // $7.5M
            borrowBaseLimit: 0,
            borrowMaxLimitInUSD: 20_000_000, // $20M
            borrowMaxLimit: 0
        });

        // ETH | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(ETH_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, ETH_USDC_USDT);
        }

        // wstETH | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(wstETH_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, wstETH_USDC_USDT);
        }

        // weETH | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(weETH_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, weETH_USDC_USDT);
        }

        // WBTC | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(WBTC_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, WBTC_USDC_USDT);
        }

        // cbBTC | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(cbBTC_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, cbBTC_USDC_USDT);
        }

        // sUSDe | USDC-USDT - Only withdrawal limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(sUSDe_USDC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;
            setVaultSupplyConfig(vaultConfig, sUSDe_USDC_USDT);
        }

        // cbBTC-WBTC | USDC - Only borrow limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(cbBTC_WBTC_USDC).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;

            setVaultBorrowConfig(vaultConfig, cbBTC_WBTC_USDC);
        }

        // cbBTC-WBTC | USDT - Only borrow limit on Liquidity Layer.
        {
            FluidVault.ConstantViews memory data_ = FluidVault(cbBTC_WBTC_USDT).constantsView();
            vaultConfig.vaultId = data_.vaultId;
            vaultConfig.supplyToken = data_.supplyToken;
            vaultConfig.borrowToken = data_.borrowToken;

            setVaultBorrowConfig(vaultConfig, cbBTC_WBTC_USDT);
        }
    }

    function setVaultBorrowConfig(VaultConfig memory vaultConfig, address vaultAddress) internal {
        AdminModuleStructs.UserBorrowConfig[] memory configs_ = new AdminModuleStructs.UserBorrowConfig[](1);

        configs_[0] = AdminModuleStructs.UserBorrowConfig({
            user: address(vaultAddress),
            token: vaultConfig.borrowToken,
            mode: vaultConfig.borrowMode,
            expandPercent: vaultConfig.borrowExpandPercent,
            expandDuration: vaultConfig.borrowExpandDuration,
            baseDebtCeiling: getRawAmount(
                vaultConfig.borrowToken, vaultConfig.borrowBaseLimit, vaultConfig.borrowBaseLimitInUSD, false
            ),
            maxDebtCeiling: getRawAmount(
                vaultConfig.borrowToken, vaultConfig.borrowMaxLimit, vaultConfig.borrowMaxLimitInUSD, false
            )
        });

        LIQUIDITY.updateUserBorrowConfigs(configs_);
    }

    function setVaultSupplyConfig(VaultConfig memory vaultConfig_, address vaultAddress) internal {
        AdminModuleStructs.UserSupplyConfig[] memory configs_ = new AdminModuleStructs.UserSupplyConfig[](1);

        configs_[0] = AdminModuleStructs.UserSupplyConfig({
            user: address(vaultAddress),
            token: vaultConfig_.supplyToken,
            mode: vaultConfig_.supplyMode,
            expandPercent: vaultConfig_.supplyExpandPercent,
            expandDuration: vaultConfig_.supplyExpandDuration,
            baseWithdrawalLimit: getRawAmount(
                vaultConfig_.supplyToken, vaultConfig_.supplyBaseLimit, vaultConfig_.supplyBaseLimitInUSD, true
            )
        });

        LIQUIDITY.updateUserSupplyConfigs(configs_);
    }

    function getRawAmount(address token, uint256 amount, uint256 amountInUSD, bool isSupply)
        public
        view
        returns (uint256)
    {
        if (amount > 0 && amountInUSD > 0) {
            revert("both usd and amount are not zero");
        }
        uint256 exchangePriceAndConfig_ = LIQUIDITY.readFromStorage(
            LiquiditySlotsLink.calculateMappingStorageSlot(
                LiquiditySlotsLink.LIQUIDITY_EXCHANGE_PRICES_MAPPING_SLOT, token
            )
        );

        (uint256 supplyExchangePrice, uint256 borrowExchangePrice) =
            LiquidityCalcs.calcExchangePrices(exchangePriceAndConfig_);

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

        uint256 exchangePrice = isSupply ? supplyExchangePrice : borrowExchangePrice;

        if (amount > 0) {
            return (amount * 1e12) / exchangePrice;
        } else {
            return (amountInUSD * 1e12 * (10 ** decimals)) / (usdPrice * exchangePrice);
        }
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
            mode: 0, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseWithdrawalLimit: token0Config_.baseWithdrawalLimit
        });
        supplyParams_[1] = AdminModuleStructs.UserSupplyConfig({
            user: dex_,
            token: token1_,
            mode: 0, // @TODO - to be filled
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
            mode: 0, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseDebtCeiling: token0Config_.baseDebtCeiling,
            maxDebtCeiling: token0Config_.maxDebtCeiling
        });
        borrowParams_[1] = AdminModuleStructs.UserBorrowConfig({
            user: dex_,
            token: token1_,
            mode: 0, // @TODO - to be filled
            expandPercent: 20 * 1e2, // @TODO - to be filled
            expandDuration: 12 hours, // @TODO - to be filled
            baseDebtCeiling: token1Config_.baseDebtCeiling,
            maxDebtCeiling: token1Config_.maxDebtCeiling
        });

        LIQUIDITY.updateUserBorrowConfigs(borrowParams_);
    }
}
