pragma solidity >=0.7.0;
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

interface ILite {
    function setAdmin(address newAdmin) external;

    function getAdmin() external view returns (address);

    function removeImplementation(address implementation_) external;

    function addImplementation(
        address implementation_,
        bytes4[] calldata sigs_
    ) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function updateMaxRiskRatio(
        uint8[] memory protocolId_,
        uint256[] memory newRiskRatio_
    ) external;

    function updateAggrMaxVaultRatio(uint256 newAggrMaxVaultRatio_) external;
}

interface IDSAV2 {
    function cast(
        string[] memory _targetNames,
        bytes[] memory _datas,
        address _origin
    ) external payable returns (bytes32);

    function isAuth(address user) external view returns (bool);
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

interface IERC20 {
    function allowance(
        address spender,
        address caller
    ) external view returns (uint256);
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

contract PayloadIGP35 {
    uint256 public constant PROPOSAL_ID = 35;

    address public constant PROPOSER =
        0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    address public constant PROPOSER_AVO_MULTISIG =
        0x059A94A72951c0ae1cc1CE3BF0dB52421bbE8210;

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

    IDSAV2 public constant TREASURY =
        IDSAV2(0x28849D2b63fA8D361e5fc15cB8aBB13019884d09);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wstETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant weETH_ADDRESS =
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address public constant stETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant wBTC_ADDRESS =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

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

        // Action 1: call executePayload on timelock contract to execute payload related to Lite & Fluid
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

        // Action 1: Update WBTC Vaults config
        action1();

        // Action 2: Remove WBTC/USDC and WBTC/USDT rewards
        action2();

        // Action 3: Set ListTokenAuth as auth on Liquidity
        action3();

        // Action 4: Set CollectRevenueAuth as auth on Liquidity
        action4();

        // Action 5: Collect revenue from Liquditiy Layer
        action5();

        // Action 6: Remove sUSDe handlers from sUSDe vaults
        action6();

        // Action 7: Make sUSDe Vaults borrow rate magnifier 1x
        action7();

        // Action 8: Transfer stETH from Treasury to Team Multisig
        action8();

        // Action 9: Add new LendingRewards contracts
        action9();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update WBTC Vaults config
    function action1() internal {
        VaultConfig[] memory configs_ = new VaultConfig[](3);

        uint256 i;

        // WBTC_USDC
        {
            configs_[i++] = VaultConfig({
                vaultId: 21,
                collateralFactor: 85 * 1e2,
                liquidationThreshold: 88 * 1e2,
                liquidationMaxLimit: 92.5 * 1e2
            });
        }

        // WBTC_USDT
        {
            configs_[i++] = VaultConfig({
                vaultId: 22,
                collateralFactor: 85 * 1e2,
                liquidationThreshold: 88 * 1e2,
                liquidationMaxLimit: 92.5 * 1e2
            });
        }

        // WBTC_ETH
        {
            configs_[i++] = VaultConfig({
                vaultId: 23,
                collateralFactor: 90 * 1e2,
                liquidationThreshold: 93 * 1e2,
                liquidationMaxLimit: 95 * 1e2
            });
        }

        _updateVaultConfig(configs_);
    }

    /// @notice Action 2: remove WBTC/USDC and WBTC/USDT rewards
    function action2() internal {
        // WBTC/USDC
        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(21),
            0xF561347c306E3Ccf213b73Ce2353D6ed79f92408,
            false
        );

        // WBTC/USDT
        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(22),
            0x36C677a6AbDa7D6409fB74d1136A65aF1415F539,
            false
        );
    }

    /// @notice Action 3: Set ListTokenAuth as auth on Liquidity
    function action3() internal {
        AdminModuleStructs.AddressBool[] memory addrBools_ = new AdminModuleStructs.AddressBool[](1);

        // ListTokenAuth
        addrBools_[0] = AdminModuleStructs.AddressBool({
            addr: 0xb2875c793CE2277dE813953D7306506E87842b76,
            value: true
        });

        LIQUIDITY.updateAuths(addrBools_);
    }

    /// @notice Action 4: Set CollectRevenueAuth as auth on Liquidity
     function action4() internal {
        AdminModuleStructs.AddressBool[] memory addrBools_ = new AdminModuleStructs.AddressBool[](1);

        // CollectRevenueAuth
        addrBools_[0] = AdminModuleStructs.AddressBool({
            addr: 0x7f14c42F84cb940F2619DD2698EDdB1C3fFC514E,
            value: true
        });

        LIQUIDITY.updateAuths(addrBools_);
    }

    /// @notice Action 5: Collect revenue from Liquditiy Layer
    function action5() internal {
        address[] memory tokens = new address[](5);

        tokens[0] = ETH_ADDRESS;
        tokens[1] = wstETH_ADDRESS;
        tokens[2] = USDC_ADDRESS;
        tokens[3] = USDT_ADDRESS;
        tokens[4] = wBTC_ADDRESS;

        LIQUIDITY.collectRevenue(tokens);
    }

    /// @notice Action 6: Remove sUSDe handlers from sUSDe vaults
    function action6() internal {
        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(7),
            0x36639DAd77eC858574aaF07a68bBa62b7db19FfA, // Vault_SUSDE_USDC
            false
        );

        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(8),
            0xafE3974f4916140a093F1de7Fc064A3Da220DD41, // Vault_SUSDE_USDT
            false
        );

        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(17),
            0xa7C805988f04f0e841504761E5aa8387600e430b, // Vault_SUSDE_USDC
            false
        );

        VAULT_T1_FACTORY.setVaultAuth(
            getVaultAddress(18),
            0x7607968F40d7Ac4Ef39E809F29fADDe34C00A0A6, // Vault_SUSDE_USDT
            false
        );
    }

    /// @notice Action 7: Make sUSDe Vaults borrow rate magnifier 1x
    function action7() internal {
        IFluidVaultT1(getVaultAddress(7)).updateBorrowRateMagnifier(100 * 1e2);
        IFluidVaultT1(getVaultAddress(8)).updateBorrowRateMagnifier(100 * 1e2);
        IFluidVaultT1(getVaultAddress(17)).updateBorrowRateMagnifier(100 * 1e2);
        IFluidVaultT1(getVaultAddress(18)).updateBorrowRateMagnifier(100 * 1e2);
    }

    /// @notice Action 8: Transfer stETH from Treasury to Team Multisig
    function action8() internal {
        string[] memory targets = new string[](1);
        bytes[] memory encodedSpells = new bytes[](1);

        string memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer stETH
        {
            uint256 stETH_AMOUNT = 300 * 1e18; // 300 stETH
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(
                withdrawSignature,
                stETH_ADDRESS,
                stETH_AMOUNT,
                TEAM_MULTISIG,
                0,
                0
            );
        }

        IDSAV2(TREASURY).cast(targets, encodedSpells, address(this));
    }

    /// @notice Action 9: Add new LendingRewards contracts
    function action9() internal {
        address[] memory protocols = new address[](2);
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);

        { /// fUSDC
            IFTokenAdmin(F_USDC).updateRewards(
                0x99c1515fa3327B048FCB46483ac0fceB0ED8d471
            );

            uint256 allowance = IERC20(USDC_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDC
            );

            protocols[0] = F_USDC;
            tokens[0] = USDC_ADDRESS;
            amounts[0] = allowance + (205_000 * 1e6);
        }

        { /// fUSDT
            IFTokenAdmin(F_USDT).updateRewards(
                0x99c1515fa3327B048FCB46483ac0fceB0ED8d471
            );

            uint256 allowance = IERC20(USDT_ADDRESS).allowance(
                address(FLUID_RESERVE),
                F_USDT
            );

            protocols[0] = F_USDT;
            tokens[0] = USDT_ADDRESS;
            amounts[0] = allowance + (205_000 * 1e6);
        }
    }
    

    /// Helpers ///
    struct VaultConfig {
        uint256 vaultId;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 liquidationMaxLimit;
    }

    function getVaultAddress(uint256 id) internal view returns(address) {
        return VAULT_T1_FACTORY.getVaultAddress(id);
    } 

    function _updateVaultConfig(VaultConfig[] memory configs_) internal {
        for (uint i = 0; i < configs_.length; i++) {
            VaultConfig memory config_ = configs_[i];

            IFluidVaultT1 vault_ = IFluidVaultT1(
                VAULT_T1_FACTORY.getVaultAddress(config_.vaultId)
            );
            vault_.updateLiquidationMaxLimit(config_.liquidationMaxLimit);
            vault_.updateLiquidationThreshold(config_.liquidationThreshold);
            vault_.updateCollateralFactor(config_.collateralFactor);
        }
    }
}
