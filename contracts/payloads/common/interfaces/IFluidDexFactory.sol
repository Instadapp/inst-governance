pragma solidity ^0.8.21;

interface IFluidDexFactory {
    /// @notice                         Computes the address of a dex based on its given ID (`dexId_`).
    /// @param dexId_                   The ID of the dex.
    /// @return dex_                    Returns the computed address of the dex.
    function getDexAddress(uint256 dexId_) external view returns (address dex_);

    function setDexAuth(address dex_, address dexAuth_, bool allowed_) external;

    function owner() external view returns (address);

    function setDexDeploymentLogic(
        address deploymentLogic_,
        bool allowed_
    ) external;
}