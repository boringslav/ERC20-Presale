// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Treasury} from "./Treasury.sol";
import {VestingModule} from "./VestingModule.sol";
import {IFactory} from "./interfaces/IFactory.sol";

contract Factory is IFactory {
    error Factory__OnlyOwner();

    event TreasuryDeployed(address indexed treasury);
    event VestingModuleDeployed(address indexed bootstrapModule);

    address public s_owner;
    address public s_treasury;
    address public s_vestingModule;

    constructor() {
        s_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Factory__OnlyOwner();
        _;
    }

    function deployBootstrapModule(bytes32 _salt) external onlyOwner {
        s_vestingModule = address(new VestingModule{salt: _salt}());
        emit VestingModuleDeployed(s_vestingModule);
    }

    function deployTreasury(bytes32 _salt) external onlyOwner {
        s_treasury = address(new Treasury{salt: _salt}());
        emit TreasuryDeployed(s_treasury);
    }
}
