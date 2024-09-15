// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {ITreasury} from "../src/interfaces/ITreasury.sol";
import {IBootstrapModule} from "../src/interfaces/IBootstrapModule.sol";

contract Base is Test {
    Factory public s_factory;

    ITreasury public s_treasury;
    IBootstrapModule public s_bootstrapModule;
    ERC20Mock public s_erc20Mock;

    bytes32 public s_treasurySalt = bytes32("TREASURY");
    bytes32 public s_bootstrapModuleSalt = bytes32("BOOTSTRAP_MODULE");

    address public DEPLOYER;
    address public TOKEN_OFFERER;
    address public USER1;

    function setUp() public {
        vm.startBroadcast(DEPLOYER);
        s_factory = new Factory();
        // Deploy Treasury and BootstrapModule
        s_factory.deployTreasury(s_treasurySalt);
        s_treasury = ITreasury(s_factory.s_treasury());
        s_factory.deployBootstrapModule(s_bootstrapModuleSalt);
        s_bootstrapModule = IBootstrapModule(s_factory.s_bootstrapModule());
        vm.stopBroadcast();

        // Create contract addresses
        DEPLOYER = makeAddr("DEPLOYER");
        TOKEN_OFFERER = makeAddr("TOKEN_OFFERER");
        USER1 = makeAddr("USER1");

        // Deal Some $
        vm.deal(DEPLOYER, 100 ether);
        vm.deal(TOKEN_OFFERER, 100 ether);
        vm.deal(USER1, 1000 ether);

        vm.startBroadcast(TOKEN_OFFERER);
        s_erc20Mock = new ERC20Mock("TestToken", "TT");
        // Mint 100 tokens to TOKEN_OFFERER
        s_erc20Mock.mint(TOKEN_OFFERER, 100 ether);
        // Approve Treasury to spend 100 tokens from TOKEN_OFFERER
        s_erc20Mock.approve(address(s_treasury), 100 ether);
        vm.stopBroadcast();
    }

    function testFactoryOnlyOwner() public {
        vm.expectRevert(Factory.Factory__OnlyOwner.selector);
        s_factory.deployTreasury(s_treasurySalt);
        vm.expectRevert(Factory.Factory__OnlyOwner.selector);
        s_factory.deployBootstrapModule(s_bootstrapModuleSalt);
    }
}
