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

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);
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

contract PayloadIGP37 {
    uint256 public constant PROPOSAL_ID = 37;

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

    IDSAV2 public constant TREASURY =
        IDSAV2(0x28849D2b63fA8D361e5fc15cB8aBB13019884d09);

    address public immutable ADDRESS_THIS;

    address public constant TEAM_MULTISIG =
        0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    ILite public constant LITE =
        ILite(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

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

        // Action 1: Update UserModule, AdminModule, ZircuitTransferModule, DummyImplementation on Liquidity Layer
        action1();

        // Action 2: Remove and new wstETH/ETH Buffer rate handler as auth on Liquidity
        action2();

        // Action 3: Update iETHv2 Lite Implementations
        action3();

        // Action 4: Set Configs on iETHv2 Lite
        action4();
    }

    function verifyProposal() external view {}

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Update UserModule, AdminModule, ZircuitTransferModule, DummyImplementation on Liquidity Layer.
    function action1() internal {
        // UserModule
        {
        bytes4[] memory sigs_ = IProxy(address(LIQUIDITY)).getImplementationSigs(0xb290b44D34C4a44E233af73998C543832c418120);
        IProxy(address(LIQUIDITY)).removeImplementation(0xb290b44D34C4a44E233af73998C543832c418120);

            IProxy(address(LIQUIDITY)).addImplementation(
                0x8eC5e29eA39b2f64B21e32cB9Ff11D5059982F8C,
                sigs_
            );
        }

        // AdminModule
        {
            bytes4[] memory sigs_ = IProxy(address(LIQUIDITY)).getImplementationSigs(0xBDF3e6A0c721117B69150D00D9Fb27873023E4Df);
            IProxy(address(LIQUIDITY)).removeImplementation(0xBDF3e6A0c721117B69150D00D9Fb27873023E4Df);

            // Add the new signature
            bytes4 newSig = bytes4(keccak256("updateUserWithdrawalLimit(address,address,uint256)"));
            bytes4[] memory newSigs = new bytes4[](sigs_.length + 1);
            for (uint i = 0; i < sigs_.length; i++) {
                newSigs[i] = sigs_[i];
            }
            newSigs[sigs_.length] = newSig;

            IProxy(address(LIQUIDITY)).addImplementation(
                0xC3800E7527145837e525cfA6AD96B6B5DaE01586,
                newSigs
            );
        }

        // ZircuitTransferModule
        {
            IProxy(address(LIQUIDITY)).removeImplementation(0xaD99E8416f505aCE0A087C5dAB7214F15aE3D1d1);
            bytes4[] memory sigs_ = new bytes4[](4);
            sigs_[0] = bytes4(keccak256("depositZircuitWeETH()"));
            sigs_[1] = bytes4(keccak256("withdrawZircuitWeETH()"));
            sigs_[2] = bytes4(keccak256("depositZircuitWeETHs()"));
            sigs_[3] = bytes4(keccak256("withdrawZircuitWeETHs()"));

            IProxy(address(LIQUIDITY)).addImplementation(
                0x9191b9539DD588dB81076900deFDd79Cb1115f72,
                sigs_
            );
        }

        // Update Dummy Implementation
        {
            IProxy(address(LIQUIDITY)).setDummyImplementation(0xa57D7CeF617271F4cEa4f665D33ebcFcBA4929f6);
        }
    }


    /// @notice Action 2: Remove and new wstETH/ETH Buffer rate handler as auth on Liquidity
    function action2() internal {
        AdminModuleStructs.AddressBool[] memory addrBools_ = new AdminModuleStructs.AddressBool[](2);

        // old wstETH/ETH Buffer rate
        addrBools_[0] = AdminModuleStructs.AddressBool({
            addr: 0xDF10FE6163c1bfB99d7179e1bFC2e0Bb6128704f,
            value: false
        });

        // new wstETH/ETH Buffer rate
        addrBools_[1] = AdminModuleStructs.AddressBool({
            addr: 0xB5af15a931dA1B1a7B8DCF6E2Cd31C8a3Dd1E134,
            value: true
        });

        LIQUIDITY.updateAuths(addrBools_);
    }

    /// @notice Action 3: Update iETHv2 Lite Implementations
     function action3() internal {
        { // Admin Module
            bytes4[] memory newSigs_ = new bytes4[](1);

            newSigs_[0] = bytes4(keccak256("enableAaveV3LidoEMode()"));

            _updateLiteImplementation(
                0xA7dC9540f00358a7ca46780de2FdEBD7F673C127,
                0xe8620e95b52ec1CD29dA337519a43D8fFB07e82C,
                newSigs_,
                false
            );
        }

        { // User Module
            bytes4[] memory newSigs_ = new bytes4[](0);

            _updateLiteImplementation(
                0x7ee8b5C11b578DD1E8c02D641508A305281Bd173,
                0xC1BDdF4ca56358Ed8899b50369C191ADfb6Ec75A,
                newSigs_,
                false
            );
        }

        { // Rebalance Module
            bytes4[] memory newSigs_ = new bytes4[](0);

            _updateLiteImplementation(
                0x871176C000603665Ce1133C0aAC783B79257E9C6,
                0x7C44B02dA7826f9e14264a8E2D48a92bb86F72ee,
                newSigs_,
                false
            );
        }

        { // Refinance Module
            bytes4[] memory newSigs_ = new bytes4[](0);

            _updateLiteImplementation(
                0x4e05681632e1401a89335EDaB3E36612Ae8E1D1E,
                0x807675e4D1eC7c1c134940Ab513B288d150E8023,
                newSigs_,
                false
            );
        }

        { // Leverage Module
            bytes4[] memory newSigs_ = new bytes4[](1);

            newSigs_[0] = bytes4(keccak256("leverage(uint8,uint256,uint256,uint256,address[],uint256[],uint256,string[],bytes[],uint256)"));

            _updateLiteImplementation(
                0x5b94f032799CC36fFd3E8CA9BCeA2bA5af40d43E,
                0x42aFc927E8Ab5D14b2760625Eb188158eefB46be,
                newSigs_,
                true
            );
        }

        { // Withdrawals Module
            bytes4[] memory newSigs_ = new bytes4[](0);

            _updateLiteImplementation(
                0x6A64A3E0af38279ac7455c85b2C683f5621cE2e7,
                0x6aa752b1462e7C71aA90e9236a817263bb5E0c72,
                newSigs_,
                false
            );
        }

        { // Fluid stETH Module
            bytes4[] memory newSigs_ = new bytes4[](0);

            _updateLiteImplementation(
                0x0F1679FB1d5B2981423c757e8ea91979fabDB2D1,
                0xd23a760cD16610f67a68BADC3c5E04E9898d2789,
                newSigs_,
                false
            );
        }

        { // View Module
            bytes4[] memory newSigs_ = new bytes4[](2);

            newSigs_[0] = bytes4(keccak256("getRatioFluidNew(uint256)"));
            newSigs_[1] = bytes4(keccak256("getRatioAaveV3Lido(uint256)"));

            _updateLiteImplementation(
                0x645b137ACa041B85c057a4A396086789cFD99041,
                0x24d58FcFA6d74c5aCc1E4b6814BF5703e1CDd8a8,
                newSigs_,
                false
            );
        }

        // Update Dummy Implementation
        LITE.setDummyImplementation(0x37b1aF815f153cAfCc6BA8f503AbE05AE40099F0);
    }

    /// @notice Action 4: Set Configs on iETHv2 Lite
    function action4() internal {
        // Enable E-Mode on Lido Aave v3 Market
        {
            (bool s_, ) = LITE.call(abi.encodeWithSignature("enableAaveV3LidoEMode()"));
            if (!s_) revert("enableAaveV3LidoEMode failed");
        }
        
        // Set Max Risk Ratio for Fluid and Lido Aave v3
        {
            uint8[] memory protocolId_ =  new uint8[](2);
            uint256[] memory newRiskRatio_ = uint256[](2);

            {
                protocolId_[0] = 9;
                newRiskRatio_[0] = 95_0000;
            }

            {
                protocolId_[1] = 10;
                newRiskRatio_[1] = 93_0000;
            }

            LITE.updateMaxRiskRatio(protocolId_, newRiskRatio_);

        }
    }

    function _updateLiteImplementation(
        address oldImplementation_,
        address newImplementation_,
        bytes4[] memory newSigs_,
        bool replace_
    ) internal {
        bytes4[] memory oldSigs_;

        if (oldImplementation_ != address(0) && !replace_) oldSigs_ = LITE.getImplementationSigs(oldImplementation_);

        bytes4[] memory allSigs_ = new bytes4[](oldSigs_.length + newSigs_.length);
        uint256 j_;
        for (uint i = 0; i < oldSigs_.length; i++) {
            allSigs_[j_++] = oldSigs_[i];
        }

        for (uint i = 0; i < newSigs_.length; i++) {
            allSigs_[j_++] = newSigs_[i];
        }

        LITE.removeImplementation(oldImplementation_);
        LITE.addImplementation(newImplementation_, allSigs_);
    }
}
