// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {Treasury, ITreasury} from "../src/Treasury.sol";
import {PresaleUtils} from "../src/lib/PresaleUtils.sol";

contract TreasuryTest is Test {
    event PresaleCreated(address indexed token, uint256 indexed price);
    event PresaleStarted(address indexed token, uint256 indexed endTime);

    ERC20Mock public s_erc20Mock;
    Treasury public s_treasury;

    address public TREASURY_DEPLOYER;
    address public TOKEN_OFFERER;
    address public USER1;

    function setUp() public {
        // Create contract addresses
        TREASURY_DEPLOYER = makeAddr("TREASURY_DEPLOYER");
        TOKEN_OFFERER = makeAddr("TOKEN_OFFERER");
        USER1 = makeAddr("USER1");

        // Deal Some $
        vm.deal(TREASURY_DEPLOYER, 100 ether);
        vm.deal(TOKEN_OFFERER, 100 ether);
        vm.deal(USER1, 100 ether);

        // Deploy Treasury contract
        vm.broadcast(TREASURY_DEPLOYER);
        s_treasury = new Treasury();

        vm.startBroadcast(TOKEN_OFFERER);
        s_erc20Mock = new ERC20Mock("TestToken", "TT");
        // Mint 100 tokens to TOKEN_OFFERER
        s_erc20Mock.mint(TOKEN_OFFERER, 100 ether);
        // Approve Treasury to spend 100 tokens from TOKEN_OFFERER
        s_erc20Mock.approve(address(s_treasury), 100 ether);

        vm.stopBroadcast();
    }

    /**
     * Helper functions
     */
    function createErc20Presale(address _token, uint256 _tokenAmount, uint256 _amountToRaise) internal {
        s_treasury.createErc20Presale(_token, _tokenAmount, _amountToRaise);
    }

    /**
     *  Presale Creation
     */
    function testCreateErc20Presale() public {
        vm.startBroadcast(TOKEN_OFFERER);
        uint256 tokenAmount = 100 ether;
        uint256 amountToRaise = 100 ether;

        // Create Presale
        vm.expectEmit();
        emit PresaleCreated(address(s_erc20Mock), 1e18);
        s_treasury.createErc20Presale(address(s_erc20Mock), tokenAmount, amountToRaise);

        // Check TokenInfo
        ITreasury.TokenInfo memory tokenInfo = s_treasury.getTokenInfo(address(s_erc20Mock));
        assertEq(tokenInfo.token, address(s_erc20Mock));
        assertEq(tokenInfo.price, 1e18);
        assertEq(tokenInfo.amount, tokenAmount);
        assertEq(tokenInfo.soldAmount, 0);

        // Check PresaleInfo
        ITreasury.PresaleInfo memory presaleInfo = s_treasury.getPresaleInfo(address(s_erc20Mock));
        assertEq(presaleInfo.amountToRaise, amountToRaise);
        assertEq(presaleInfo.raisedAmount, 0);
        assertEq(presaleInfo.tokenInfo.token, address(s_erc20Mock));
        assertEq(presaleInfo.tokenInfo.price, 1e18);
        assertEq(presaleInfo.tokenInfo.amount, tokenAmount);
        assertEq(presaleInfo.tokenInfo.soldAmount, 0);
        assertEq(presaleInfo.startTime, 0);
        assertEq(presaleInfo.endTime, 0);
        assertEq(uint8(presaleInfo.status), uint8(ITreasury.PresaleStatus.PENDING));
    }

    function testCreateErc20PresaleRevert() external {
        vm.startBroadcast(TOKEN_OFFERER);
        uint256 tokenAmount = 100 ether;
        uint256 amountToRaise = 100 ether;
        s_treasury.createErc20Presale(address(s_erc20Mock), tokenAmount, amountToRaise);
        vm.expectRevert(ITreasury.Treasury__PresaleAlreadyCreatedError.selector);
        s_treasury.createErc20Presale(address(s_erc20Mock), tokenAmount, amountToRaise);
    }

    /**
     *  Presale Start
     */
    function testStartErc20Presale() external {
        vm.startBroadcast(TOKEN_OFFERER);
        // Create Presale
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);

        // Start Presale
        vm.expectEmit();
        emit PresaleStarted(address(s_erc20Mock), block.timestamp + 7 days);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);

        ITreasury.PresaleInfo memory presaleInfo = s_treasury.getPresaleInfo(address(s_erc20Mock));
        assertEq(presaleInfo.startTime, block.timestamp);
        assertEq(presaleInfo.endTime, block.timestamp + 7 days);

        vm.stopBroadcast();
    }

    function testStartErc20PresaleRevert() external {
        vm.broadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);

        vm.expectRevert(ITreasury.Treasury__CallerNotOwner.selector);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);

        vm.startBroadcast(TOKEN_OFFERER);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.expectRevert(ITreasury.Treasury__PresaleStartError.selector);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
    }

    /**
     *  Presale Price
     */
    function testPresalePrice() external {
        uint256 tokenAmount = 100 ether;
        uint256 amountToRaise = 100 ether;
        uint256 tokenPrice = s_treasury.previewPresalePrice(tokenAmount, amountToRaise);
        assertEq(tokenPrice, 1e18);

        tokenAmount = 200 ether;
        amountToRaise = 100 ether;
        tokenPrice = s_treasury.previewPresalePrice(tokenAmount, amountToRaise);
        assertEq(tokenPrice, 5e17);

        tokenAmount = 100 ether;
        amountToRaise = 200 ether;
        tokenPrice = s_treasury.previewPresalePrice(tokenAmount, amountToRaise);
        assertEq(tokenPrice, 2e18);

        tokenAmount = 0;
        amountToRaise = 100 ether;
        vm.expectRevert(PresaleUtils.PresaleUtils__DivideByZeroError.selector);
        s_treasury.previewPresalePrice(tokenAmount, amountToRaise);

        tokenAmount = 100 ether;
        amountToRaise = 0;
        vm.expectRevert(PresaleUtils.PresaleUtils__DivideByZeroError.selector);
        s_treasury.previewPresalePrice(tokenAmount, amountToRaise);
    }
}
