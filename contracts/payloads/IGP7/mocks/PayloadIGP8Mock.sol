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
    function updateSecondaryAuth(address secondaryAuth_) external;
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

contract PayloadIGP8Mock {
    uint256 public constant PROPOSAL_ID = 8;

    IGovernorBravo public constant GOVERNOR = IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public constant OLD_TIMELOCK = ITimelock(0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC);
    ITimelock public immutable TIMELOCK;
    address public immutable ADDRESS_THIS;

    IInstaIndex public constant INSTAINDEX = IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    ILite public constant LITE = ILite(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);
    IDSAV2 public constant TREASURY = IDSAV2(0x28849D2b63fA8D361e5fc15cB8aBB13019884d09);

    uint256 public constant ONE_DAY_TIME_IN_SECONDS = 1 days; // 1 day in seconds. 86400s
    uint256 public constant ONE_DAY_TIME_IN_BLOCKS = 7_200; // 1 day in blocks. 12s per block
    uint256 public constant TWO_DAY_TIME_IN_BLOCKS = 14_400; // 2 day in blocks. 12s per block

    string public constant description = "";

    address public immutable GOVERNOR_IMPLEMENTATION_ADDRESS;
    address public constant TEAM_MULTISIG = 0x4F6F977aCDD1177DCD81aB83074855EcB9C2D49e;

    constructor (address governor_, address timelock_) {
        TIMELOCK = ITimelock(address(timelock_)); 
        GOVERNOR_IMPLEMENTATION_ADDRESS = address(governor_);
        ADDRESS_THIS = address(this);
    }


    function propose() external {
        uint256 totalActions = 3;
        address[] memory targets = new address[](totalActions);
        uint256[] memory values = new uint256[](totalActions);
        string[] memory signatures = new string[](totalActions);
        bytes[] memory calldatas = new bytes[](totalActions);

        (targets[0], values[0], signatures[0], calldatas[0]) = action1();

        (targets[1], values[1], signatures[1], calldatas[1]) = action2();

        (targets[2], values[2], signatures[2], calldatas[2]) = action3();

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
       LITE.updateSecondaryAuth(msg.sender);
    }

    function verifyProposal() external view {
        // Verify 1 : Verify DSA Master
        require(INSTAINDEX.master() == address(TIMELOCK), "InstaIndex-wrong-master");

        // Verify 2 : Verify Lite Admin
        require(LITE.getAdmin() == address(TIMELOCK), "Lite-wrong-admin");

        // Verify 3 : Verify Governor Admin
        require(GOVERNOR.admin() == address(TIMELOCK), "Governor-wrong-admin");

        // Verify 4 : Verify Governor Timelock
        require(GOVERNOR.timelock() == address(TIMELOCK), "Governor-wrong-timelock");

        // Verify 5 : Verify Governor Pending Admin
        require(GOVERNOR.pendingAdmin() == address(0), "Governor-wrong-timelock");

        // Verify 6 : Verify Old Timelock Admin
        require(OLD_TIMELOCK.admin() == address(GOVERNOR), "Old-timelock-wrong-admin");

        // Verify 7 : Verify Old Timelock Pending Admin
        require(OLD_TIMELOCK.pendingAdmin() == address(TEAM_MULTISIG), "Old-timelock-wrong-pending-admin");

        // Verify 8 : Verify New Timelock Admin
        require(TIMELOCK.admin() == address(GOVERNOR), "Timelock-wrong-admin");

        // Verify 9 : Verify Timelock Pending Admin
        require(TIMELOCK.pendingAdmin() == address(0), "Old-timelock-wrong-pending-admin");

        // Verify 10 : Verify Treasury remove of old timelock
        require(TREASURY.isAuth(address(OLD_TIMELOCK)) == false, "Treasury-old-timelock-not-removed");

        // Verify 11: Verify Treasury add of new timelock
        require(TREASURY.isAuth(address(TIMELOCK)) == true, "Treasury-new-timelock-not-added");

        // Verify 12: Verify voting delay
        require(GOVERNOR.votingDelay() == ONE_DAY_TIME_IN_BLOCKS, "Voting-delay-not-set-to-one-day");

        // Verify 13: Verify voting period
        require(GOVERNOR.votingPeriod() == TWO_DAY_TIME_IN_BLOCKS, "Voting-period-not-set-to-two-day");

        // Verify 14: Verify queueing period
        require(TIMELOCK.delay() == ONE_DAY_TIME_IN_SECONDS, "Timelock-delay-not-set-to-one-day");
    }

    ///////// PROPOSAL ACTIONS - 8 Actions ///////

    /// @notice Action 1: call cast() - transfer rewards to Team Multisig, add new Timelock as auth & remove old Timelock as auth on Treasury
    function action1() public view returns(address target, uint256 value, string memory signature, bytes memory calldatas) {
        string[] memory targets = new string[](5);
        bytes[] memory encodedSpells = new bytes[](5);

        string memory withdrawSignature = "withdraw(address,uint256,address,uint256,uint256)";

        // Spell 1: Transfer wETH
        {
            address ETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            uint256 ETH_AMOUNT = 1;
            targets[0] = "BASIC-A";
            encodedSpells[0] = abi.encodeWithSignature(withdrawSignature, ETH_ADDRESS, ETH_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        // Spell 2: Transfer USDC
        {   
            address USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            uint256 USDC_AMOUNT = 100;
            targets[1] = "BASIC-A";
            encodedSpells[1] = abi.encodeWithSignature(withdrawSignature, USDC_ADDRESS, USDC_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        // Spell 3: Transfer DAI
        {   
            address DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
            uint256 DAI_AMOUNT = 100;
            targets[2] = "BASIC-A";
            encodedSpells[2] = abi.encodeWithSignature(withdrawSignature, DAI_ADDRESS, DAI_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        // Spell 4: Transfer USDT
        {   
            address USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
            uint256 USDT_AMOUNT = 100;
            targets[3] = "BASIC-A";
            encodedSpells[3] = abi.encodeWithSignature(withdrawSignature, USDT_ADDRESS, USDT_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        // Spell 5: Transfer stETH
        {   
            address STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
            uint256 STETH_AMOUNT = 1;
            targets[4] = "BASIC-A";
            encodedSpells[4] = abi.encodeWithSignature(withdrawSignature, STETH_ADDRESS, STETH_AMOUNT, TEAM_MULTISIG, 0, 0);
        }

        target = address(TREASURY);
        value = 0;
        signature = "cast(string[],bytes[],address)";
        calldatas = abi.encode(targets, encodedSpells, address(this));
    }

    function action2() public view returns(address target, uint256 value, string memory signature, bytes memory calldatas) {
        target = address(TIMELOCK);
        value = 0;
        signature = "executePayload(address,string,bytes)";
        calldatas = abi.encode(
                address(this),
                "execute()",
                abi.encode()
            );
    }

    function action3() public view returns(address target, uint256 value, string memory signature, bytes memory calldatas) {
        target = address(this);
        value = 0;
        signature = "verifyProposal()";
        calldatas = abi.encode();
    }
}