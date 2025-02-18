pragma solidity ^0.8.21;

interface ISmartLendingAdmin {
    /// @notice Updates the rebalancer address (ReserveContract). Only callable by SmartLendingFactory auths.
    function updateRebalancer(address rebalancer_) external;

    /// @dev Set the fee or reward. Only callable by auths.
    /// @param feeOrReward_ The new fee or reward (1e6 = 100%, 1e4 = 1%, minimum 0.0001% fee or reward). 0 means no fee or reward
    function setFeeOrReward(int256 feeOrReward_) external;
}