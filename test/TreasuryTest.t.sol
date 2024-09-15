// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {Treasury, ITreasury} from "../src/Treasury.sol";
import {PresaleUtils} from "../src/lib/PresaleUtils.sol";
import {Base} from "./Base.t.sol";

contract TreasuryTest is Base {
    event PresaleCreated(address indexed token, uint256 indexed price);
    event PresaleStarted(address indexed token, uint256 indexed endTime);

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
        uint256 tokenAmount = 100;
        uint256 amountToRaise = 100;

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

    /**
     *  Presale Start
     */
    function testStartErc20Presale() external {
        vm.startBroadcast(TOKEN_OFFERER);
        // Create Presale
        createErc20Presale(address(s_erc20Mock), 100, 100 ether);

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
        createErc20Presale(address(s_erc20Mock), 100, 100 ether);

        vm.expectRevert(ITreasury.Treasury__CallerNotOwner.selector);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);

        vm.startBroadcast(TOKEN_OFFERER);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.expectRevert(ITreasury.Treasury__PresaleStartError.selector);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
    }

    /**
     *  Presale Cancel
     */
    function testCancelErc20Presale() external {
        vm.startBroadcast(TOKEN_OFFERER);
        // Create Presale
        createErc20Presale(address(s_erc20Mock), 100, 100 ether);

        // Cancel Presale
        s_treasury.cancelErc20Presale(address(s_erc20Mock));

        ITreasury.PresaleInfo memory presaleInfo = s_treasury.getPresaleInfo(address(s_erc20Mock));
        assertEq(presaleInfo.amountToRaise, 0);
        assertEq(presaleInfo.raisedAmount, 0);
        assertEq(presaleInfo.tokenInfo.token, address(0));
    }

    function testCancelErc20PresaleRevertWrongOwner() external {
        vm.broadcast(TOKEN_OFFERER);
        // Create Presale
        createErc20Presale(address(s_erc20Mock), 100, 100 ether);

        vm.broadcast(USER1);
        vm.expectRevert(ITreasury.Treasury__CallerNotOwner.selector);
        s_treasury.cancelErc20Presale(address(s_erc20Mock));
    }

    function testCancelErc20PresaleRevertWrongStatus() external {
        vm.startBroadcast(TOKEN_OFFERER);
        // Create Presale
        createErc20Presale(address(s_erc20Mock), 100, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.expectRevert(ITreasury.Treasury__PresaleCannotBeCancelled.selector);
        s_treasury.cancelErc20Presale(address(s_erc20Mock));

        vm.stopBroadcast();
    }

    /**
     * Presale Buy Tokens
     */
    function testPresaleBuyErc20Tokens() external {
        // Create Presale
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100, 100);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        // Buy Tokens
        vm.startBroadcast(USER1);
        uint256 pricePerToken = s_treasury.getTokenInfo(address(s_erc20Mock)).price;
        s_treasury.buyErc20Presale{value: pricePerToken * 20}(address(s_erc20Mock), 20);
        uint256 userBalance = s_treasury.getUserPurchasedTokens(USER1, address(s_erc20Mock));

        ITreasury.PresaleInfo memory presaleInfo = s_treasury.getPresaleInfo(address(s_erc20Mock));
        vm.stopBroadcast();

        assertEq(presaleInfo.raisedAmount, pricePerToken * 20);
        assertEq(userBalance, 20);
    }

    function testPresaleBuyErc20RevertPresaleNotActive() external {
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100, 100);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        // Buy all the tokens
        uint256 pricePerToken = s_treasury.getTokenInfo(address(s_erc20Mock)).price;
        console2.log("Price Per Token: ", pricePerToken);

        vm.broadcast(USER1);
        s_treasury.buyErc20Presale{value: pricePerToken * 100}(address(s_erc20Mock), 100);
        ITreasury.PresaleInfo memory presaleInfo = s_treasury.getPresaleInfo(address(s_erc20Mock));
        ITreasury.TokenInfo memory tokenInfo = s_treasury.getTokenInfo(address(s_erc20Mock));

        assertEq(presaleInfo.raisedAmount, 100 ether);
        assertEq(tokenInfo.amount, 100);
        assertEq(tokenInfo.soldAmount, 100);

        // Try to buy more tokens
        vm.broadcast(USER1);
        vm.expectRevert(ITreasury.Treasury__PresaleNotActive.selector);
        s_treasury.buyErc20Presale{value: pricePerToken * 20}(address(s_erc20Mock), 20);
    }

    function testPresaleBuyErc20RevertPresaleExpired() external {
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        // Wait for Presale to expire
        vm.warp(14 days);

        // Buy Tokens
        vm.startBroadcast(USER1);
        uint256 pricePerToken = s_treasury.getTokenInfo(address(s_erc20Mock)).price;
        vm.expectRevert(ITreasury.Treasury__PresaleNotActive.selector);
        s_treasury.buyErc20Presale{value: pricePerToken * 20}(address(s_erc20Mock), 20);
    }

    function testPresaleBuyErc20RevertInsufficientFunds() external {
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        // Buy Tokens
        vm.startBroadcast(USER1);
        uint256 pricePerToken = s_treasury.getTokenInfo(address(s_erc20Mock)).price;
        vm.expectRevert(ITreasury.Treasury__InsufficientFunds.selector);
        s_treasury.buyErc20Presale{value: pricePerToken * 20 - 1}(address(s_erc20Mock), 20);
    }

    /**
     * Presale Sell Tokens
     */
    function testSellErc20Presale() external {
        // Create Presale
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        // Buy Tokens
        vm.startBroadcast(USER1);
        // Get treasury balance before buying tokens
        uint256 treasuryBalanceBefore = address(s_treasury).balance;

        uint256 pricePerToken = s_treasury.getTokenInfo(address(s_erc20Mock)).price;
        s_treasury.buyErc20Presale{value: pricePerToken * 20}(address(s_erc20Mock), 20);

        // Sell Tokens
        // Get user balance before selling tokens
        uint256 userBalanceBefore = address(USER1).balance;

        s_treasury.sellErc20Presale(address(s_erc20Mock), 20);
        assertEq(s_treasury.getUserPurchasedTokens(USER1, address(s_erc20Mock)), 0);
        assertEq(address(USER1).balance, userBalanceBefore + 20 ether - PresaleUtils.calculateFee(20 ether));
        assertEq(address(s_treasury).balance, treasuryBalanceBefore + PresaleUtils.calculateFee(20 ether));
        vm.stopBroadcast();
    }

    function testSellErc20PresaleRevertInsufficientFunds() external {
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        vm.startBroadcast(USER1);
        vm.expectRevert(ITreasury.Treasury__InsufficientFunds.selector);
        s_treasury.sellErc20Presale(address(s_erc20Mock), 20);
    }

    function testSellErc20PresaleRevertPresaleNotActive() external {
        vm.startBroadcast(TOKEN_OFFERER);
        createErc20Presale(address(s_erc20Mock), 100 ether, 100 ether);
        s_treasury.startErc20Presale(address(s_erc20Mock), 7 days);
        vm.stopBroadcast();

        vm.warp(14 days);

        vm.startBroadcast(USER1);
        vm.expectRevert(ITreasury.Treasury__PresaleNotActive.selector);
        s_treasury.sellErc20Presale(address(s_erc20Mock), 20);
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
