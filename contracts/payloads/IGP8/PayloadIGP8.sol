pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IGovernorBravo {
    function _acceptAdmin() external;
    function _setVotingDelay(uint newVotingDelay) external;
    function _setVotingPeriod(uint newVotingPeriod) external;
    function _acceptAdminOnTimelock() external;
    function _setImplementation(address implementation_) external;
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint);
    function admin() external view returns(address);
    function pendingAdmin() external view returns(address);
    function timelock() external view returns(address);
    function votingDelay() external view returns(uint256);
    function votingPeriod() external view returns(uint256);
}

interface ITimelock {
    function acceptAdmin() external;
    function setDelay(uint delay_) external;
    function setPendingAdmin(address pendingAdmin_) external;
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) external returns (bytes32);
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) external payable returns (bytes memory);
    function pendingAdmin() external view returns(address);
    function admin() external view returns(address);
    function delay() external view returns(uint256);
}

interface IInstaIndex {
    function changeMaster(address _newMaster) external;
    function updateMaster() external;
    function master() external view returns(address);
}

interface ILite {
    function setAdmin(address newAdmin) external;
    function getAdmin() external view returns(address);
    function removeImplementation(address implementation_) external;
    function addImplementation(
        address implementation_,
        bytes4[] calldata sigs_
    ) external;
    function setDummyImplementation(address newDummyImplementation_) external;
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

contract PayloadIGP8 {
    uint256 public constant PROPOSAL_ID = 8;

    address public constant PROPOSER = 0xA45f7bD6A5Ff45D31aaCE6bCD3d426D9328cea01;

    IGovernorBravo public constant GOVERNOR = IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public immutable TIMELOCK = ITimelock(0x2386DC45AdDed673317eF068992F19421B481F4c);

    address public immutable ADDRESS_THIS;

    ILite public constant LITE = ILite(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

    address internal constant OLD_USER_MODULE =
        0xFF93C10FB34f7069071D0679c45ed77A98f37f21;
    address internal constant OLD_ADMIN_MODULE =
        0x06feaa505193e987B12f161F1dB73b1D4d604001;
    address internal constant OLD_LEVERAGE_MODULE =
        0xA18519a6bb1282954e933DA0A775924E4CcE6019;
    address internal constant OLD_REBALANCER_MODULE =
        0xc6639CE123d779fE6eA545B70CbDc1dCA421740d;
    address internal constant OLD_REFINANCE_MODULE =
        0x390936658cB9B73ca75c6c02D5EF88b958D38241;
    address internal constant OLD_DSA_MODULE =
        0xbd45DfF3320b0d832C61fb41489fdd3a1b960067;

    address internal constant NEW_USER_MODULE =
        0xFF93C10FB34f7069071D0679c45ed77A98f37f21;
    address internal constant NEW_ADMIN_MODULE =
        0x06feaa505193e987B12f161F1dB73b1D4d604001;
    address internal constant NEW_LEVERAGE_MODULE =
        0xA18519a6bb1282954e933DA0A775924E4CcE6019;
    address internal constant NEW_REBALANCER_MODULE =
        0xc6639CE123d779fE6eA545B70CbDc1dCA421740d;
    address internal constant NEW_REFINANCE_MODULE =
        0x390936658cB9B73ca75c6c02D5EF88b958D38241;
    address internal constant NEW_DSA_MODULE =
        0xE38d5938d6D75ceF2c3Fc63Dc4AB32cD103E10df;
    address internal constant NEW_WITHDRAWALS_MODULE =
        0xbd45DfF3320b0d832C61fb41489fdd3a1b960067;

    address internal constant NEW_DUMMY_IMPLEMENTATION =
        0x5C122207f668D3fE345465Ac447b3FEF627f4963;

    constructor () {
        ADDRESS_THIS = address(this);
    }


    function propose(string memory description) external {
        require(msg.sender == PROPOSER, "msg.sender-not-proposer");

        uint256 totalActions = 1;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        // Action 1: call executePayload on timelock contract to execute payload related to lite
        targets[0] = address(TIMELOCK);
        values[0] = 0;
        signatures[0] = "executePayload(address,string,bytes)";
        calldatas[0] = abi.encode(
            ADDRESS_THIS,
            "execute()",
            abi.encode()
        );

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
        // Action 1: remove Implementations
       action1();

        // Action 2: add implementations
       action2();

        // Action 3: set dummy implementations
        action3();

        // Action 4: verify proposal
    }

    function verifyProposal() external view {
    }

    /***********************************|
    |     Proposal Payload Actions      |
    |__________________________________*/

    /// @notice Action 1: Remove all old implementations
    function action1() internal {
        LITE.removeImplementation(OLD_USER_MODULE);
        LITE.removeImplementation(OLD_ADMIN_MODULE);
        LITE.removeImplementation(OLD_LEVERAGE_MODULE);
        LITE.removeImplementation(OLD_REBALANCER_MODULE);
        LITE.removeImplementation(OLD_REFINANCE_MODULE);
        LITE.removeImplementation(OLD_DSA_MODULE);
    }

    /// @notice Action 2: Add new implementations
    function action2() internal {
        LITE.addImplementation(NEW_USER_MODULE, userSigs());
        LITE.addImplementation(NEW_ADMIN_MODULE, adminSigs());
        LITE.addImplementation(NEW_LEVERAGE_MODULE, leverageSigs());
        LITE.addImplementation(NEW_REBALANCER_MODULE, rebalancerSigs());
        LITE.addImplementation(NEW_REFINANCE_MODULE, refinanceSigs());
        LITE.addImplementation(NEW_DSA_MODULE, dsaSigs());
        LITE.addImplementation(NEW_WITHDRAWALS_MODULE, withdrawalsSigs());
    }

    /// @notice Action 3: call changeMaster() - change ownership of DSA to new timelock contract
    function action3() internal {
        LITE.setDummyImplementation(NEW_DUMMY_IMPLEMENTATION);
    }

    /***********************************|
    |          Function Signatures      |
    |__________________________________*/
    function userSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](54);
        sigs_[0] = bytes4(keccak256("allowance(address,address)"));
        sigs_[1] = bytes4(keccak256("approve(address,uint256)"));
        sigs_[2] = bytes4(keccak256("balanceOf(address)"));
        sigs_[3] = bytes4(keccak256("decreaseAllowance(address,uint256)"));
        sigs_[4] = bytes4(keccak256("increaseAllowance(address,uint256)"));
        sigs_[5] = bytes4(keccak256("name()"));
        sigs_[6] = bytes4(keccak256("symbol()"));
        sigs_[7] = bytes4(keccak256("totalSupply()"));
        sigs_[8] = bytes4(keccak256("transfer(address,uint256)"));
        sigs_[9] = bytes4(keccak256("transferFrom(address,address,uint256)"));
        sigs_[10] = bytes4(keccak256("asset()"));
        sigs_[11] = bytes4(keccak256("convertToAssets(uint256)"));
        sigs_[12] = bytes4(keccak256("convertToShares(uint256)"));
        sigs_[13] = bytes4(keccak256("decimals()"));
        sigs_[14] = bytes4(keccak256("maxDeposit(address)"));
        sigs_[15] = bytes4(keccak256("maxMint(address)"));
        sigs_[16] = bytes4(keccak256("maxRedeem(address)"));
        sigs_[17] = bytes4(keccak256("maxWithdraw(address)"));
        sigs_[18] = bytes4(keccak256("previewDeposit(uint256)"));
        sigs_[19] = bytes4(keccak256("previewMint(uint256)"));
        sigs_[20] = bytes4(keccak256("previewRedeem(uint256)"));
        sigs_[21] = bytes4(keccak256("previewWithdraw(uint256)"));
        sigs_[22] = bytes4(keccak256("getNetAssets()"));
        sigs_[23] = bytes4(keccak256("getProtocolRatio(uint8)"));
        sigs_[24] = bytes4(keccak256("getRatioAaveV2()"));
        sigs_[25] = bytes4(keccak256("getRatioAaveV3(uint256)"));
        sigs_[26] = bytes4(keccak256("getRatioCompoundV3(uint256)"));
        sigs_[27] = bytes4(keccak256("getRatioEuler(uint256)"));
        sigs_[28] = bytes4(keccak256("getRatioMorphoAaveV2()"));
        sigs_[29] = bytes4(keccak256("getWithdrawFee(uint256)"));
        sigs_[30] = bytes4(keccak256("aggrMaxVaultRatio()"));
        sigs_[31] = bytes4(keccak256("exchangePrice()"));
        sigs_[32] = bytes4(keccak256("isRebalancer(address)"));
        sigs_[33] = bytes4(keccak256("leverageMaxUnitAmountLimit()"));
        sigs_[34] = bytes4(keccak256("maxRiskRatio(uint8)"));
        sigs_[35] = bytes4(keccak256("revenue()"));
        sigs_[36] = bytes4(keccak256("revenueExchangePrice()"));
        sigs_[37] = bytes4(keccak256("revenueFeePercentage()"));
        sigs_[38] = bytes4(keccak256("secondaryAuth()"));
        sigs_[39] = bytes4(keccak256("treasury()"));
        sigs_[40] = bytes4(keccak256("vaultDSA()"));
        sigs_[41] = bytes4(keccak256("withdrawFeeAbsoluteMin()"));
        sigs_[42] = bytes4(keccak256("withdrawalFeePercentage()"));
        sigs_[43] = bytes4(keccak256("deposit(uint256,address)"));
        sigs_[44] = bytes4(
            keccak256("importPosition(uint256,uint256,uint256,address)")
        );
        sigs_[45] = bytes4(keccak256("mint(uint256,address)"));
        sigs_[46] = bytes4(keccak256("redeem(uint256,address,address)"));
        sigs_[47] = bytes4(keccak256("totalAssets()"));
        sigs_[48] = bytes4(keccak256("withdraw(uint256,address,address)"));
        // new functions
        sigs_[49] = bytes4(keccak256("borrowBalanceMorphoAaveV3(address)"));
        sigs_[50] = bytes4(keccak256("collateralBalanceMorphoAaveV3(address)"));
        sigs_[51] = bytes4(keccak256("getRatioMorphoAaveV3(uint256)"));
        sigs_[52] = bytes4(keccak256("getRatioSpark(uint256)"));
        sigs_[53] = bytes4(keccak256("queuedWithdrawStEth()"));
        // TODO: add new function
    }

    function adminSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](10);
        sigs_[0] = bytes4(keccak256("changeVaultStatus(uint8)"));
        sigs_[1] = bytes4(keccak256("reduceAggrMaxVaultRatio(uint256)"));
        sigs_[2] = bytes4(keccak256("reduceMaxRiskRatio(uint8[],uint256[])"));
        sigs_[3] = bytes4(keccak256("updateAggrMaxVaultRatio(uint256)"));
        sigs_[4] = bytes4(keccak256("updateFees(uint256,uint256,uint256)"));
        sigs_[5] = bytes4(
            keccak256("updateLeverageMaxUnitAmountLimit(uint256)")
        );
        sigs_[6] = bytes4(keccak256("updateMaxRiskRatio(uint8[],uint256[])"));
        sigs_[7] = bytes4(keccak256("updateRebalancer(address,bool)"));
        sigs_[8] = bytes4(keccak256("updateSecondaryAuth(address)"));
        sigs_[9] = bytes4(keccak256("updateTreasury(address)"));
    }

    function leverageSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](1);
        sigs_[0] = bytes4(
            keccak256(
                "leverage(uint8,uint256,uint256,uint256,address[],uint256[],uint256,uint256,bytes)"
            )
        );
    }

    function rebalancerSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](6);
        sigs_[0] = bytes4(keccak256("collectRevenue(uint256)"));
        sigs_[1] = bytes4(keccak256("fillVaultAvailability(uint8,uint256)"));
        sigs_[2] = bytes4(keccak256("sweepEthToSteth()"));
        sigs_[3] = bytes4(keccak256("sweepWethToSteth()"));
        sigs_[4] = bytes4(keccak256("updateExchangePrice()"));
        sigs_[5] = bytes4(keccak256("vaultToProtocolDeposit(uint8,uint256)"));
    }

    function refinanceSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](1);
        sigs_[0] = bytes4(
            keccak256("refinance(uint8,uint8,uint256,uint256,uint256,uint256)")
        );
    }

    function dsaSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](2);
        sigs_[0] = bytes4(keccak256("addDSAAuth(address)"));
        sigs_[1] = bytes4(keccak256("spell(address,bytes,uint256,uint256)"));
    }

    function withdrawalsSigs() public pure returns (bytes4[] memory sigs_) {
        sigs_ = new bytes4[](4);
        // new functions
        sigs_[0] = bytes4(
            keccak256("onERC721Received(address,address,uint256,bytes)")
        );
        sigs_[1] = bytes4(keccak256("queueEthWithdrawal(uint256,uint8)"));
        sigs_[2] = bytes4(keccak256("paybackDebt(uint8)"));
        sigs_[3] = bytes4(keccak256("claimEthWithdrawal(uint256,uint8)"));
    }
}