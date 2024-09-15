// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IFactory {
    function deployTreasury(bytes32 _salt) external;
    function deployBootstrapModule(bytes32 _salt) external;
}
