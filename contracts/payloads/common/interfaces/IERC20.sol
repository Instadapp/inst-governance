pragma solidity ^0.8.21;

interface IERC20 {
    function allowance(
        address spender,
        address caller
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}