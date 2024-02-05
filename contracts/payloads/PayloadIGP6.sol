pragma solidity ^0.7.0;

import "../SafeMath.sol";

interface IGovernorBravo {
    function _acceptAdmin() external;
    function _setVotingDelay(uint newVotingDelay) external;
    function _setVotingPeriod(uint newVotingPeriod) external;
    function _acceptAdminOnTimelock() external;
}

interface ITimelock {
    function acceptAdmin() external;
    function setDelay(uint delay_) external;
    function setPendingAdmin(address pendingAdmin_) external;
}

interface IInstaIndex {
    function updateMaster() external;
}

contract PayloadIGP {
    uint256 public constant PROPOSAL_ID = 6;

    IGovernorBravo public constant GOVERNOR = IGovernorBravo(0x0204Cd037B2ec03605CFdFe482D8e257C765fA1B);
    ITimelock public constant OLD_TIMELOCK = ITimelock(0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC);
    ITimelock public constant TIMELOCK = ITimelock(0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC);
    IInstaIndex public constant INSTAINDEX = IInstaIndex(0xC7Cb1dE2721BFC0E0DA1b9D526bCdC54eF1C0eFC);

    uint256 public constant ONE_DAY_TIME_IN_SECONDS = 1 days; // 1 day in seconds. 86400s
    uint256 public constant ONE_DAY_TIME_IN_BLOCKS = 7_200; // 1 day in blocks. 12s per block
    uint256 public constant TWO_DAY_TIME_IN_BLOCKS = 14_400; // 2 day in blocks. 12s per block

    function execute() external {
        // Action 1: _acceptAdmin() function on governor contract
        GOVERNOR._acceptAdmin();

        // Action 2: acceptAdmin() function on old time contract
        OLD_TIMELOCK.acceptAdmin();
        
        // Action 2: updateMaster() function on DSA instaIndex
        INSTAINDEX.updateMaster();

        // Action 4: setDelay() on new timelock contract with 1 day
        TIMELOCK.setDelay(ONE_DAY_TIME_IN_SECONDS);

        // Action 5: setPendingAdmin() on new timelock contract
        TIMELOCK.setPendingAdmin(address(GOVERNOR));

        // Action 6: _acceptAdminOnTimelock() on governor contract
        GOVERNOR._acceptAdminOnTimelock();

        // Action 7: _setVotingDelay() function on governor contract with 1 days
        GOVERNOR._setVotingDelay(ONE_DAY_TIME_IN_BLOCKS);

        // Action 8: _setVotingPeriod() function on governor contract with 2 days
        GOVERNOR._setVotingPeriod(TWO_DAY_TIME_IN_BLOCKS);
    }

    function verifyProposal() external {

    }
}