
pragma solidity ^0.8.21;

interface IProxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}