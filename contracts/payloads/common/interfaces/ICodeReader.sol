// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ICodeReader {
    function readCode(address target) external view returns (bytes memory);
} 