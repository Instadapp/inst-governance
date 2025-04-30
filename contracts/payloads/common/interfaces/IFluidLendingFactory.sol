pragma solidity ^0.8.21;

interface IFluidLendingFactory {
    /// @notice Computes the address of a token based on the asset and fToken type.
    /// @param asset_ The address of the underlying asset.
    /// @param fTokenType_ The type of fToken (e.g., "fToken" or "NativeUnderlying").
    /// @return The computed address of the token.
    function computeToken(address asset_, string calldata fTokenType_) external view returns (address);

}