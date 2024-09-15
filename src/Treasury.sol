// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {PresaleUtils} from "./lib/PresaleUtils.sol";

contract Treasury is ITreasury {
    mapping(address token => PresaleInfo) public s_presaleInfo;
    mapping(address token => TokenInfo) public s_tokenInfo;
    mapping(address token => mapping(address user => uint256 amount)) public s_userPurchasedTokens;

    modifier checkIsPresaleActive(address token) {
        PresaleInfo storage presaleInfo = s_presaleInfo[token];
        TokenInfo storage tokenInfo = s_tokenInfo[token];

        if (presaleInfo.endTime < block.timestamp) {
            presaleInfo.status = PresaleStatus.COMPLETED;
        }

        if (tokenInfo.amount == tokenInfo.soldAmount) {
            presaleInfo.status = PresaleStatus.COMPLETED;
        }
        _;
    }

    /**
     * @inheritdoc ITreasury
     */
    function createErc20Presale(address _token, uint256 _tokenAmount, uint256 _amountToRaise) external override {
        if (s_presaleInfo[_token].owner != address(0)) {
            revert Treasury__PresaleAlreadyCreatedError();
        }

        uint256 tokenPrice = PresaleUtils.calculatePresalePrice(_tokenAmount, _amountToRaise);
        TokenInfo memory tokenInfo = TokenInfo({token: _token, price: tokenPrice, amount: _tokenAmount, soldAmount: 0});

        s_presaleInfo[_token] = PresaleInfo({
            amountToRaise: _amountToRaise,
            raisedAmount: 0,
            tokenInfo: tokenInfo,
            startTime: 0,
            endTime: 0,
            status: PresaleStatus.PENDING,
            owner: msg.sender
        });

        s_tokenInfo[_token] = tokenInfo;

        SafeTransferLib.safeTransferFrom(_token, msg.sender, address(this), _tokenAmount);
        emit PresaleCreated(_token, tokenPrice);
    }

    /**
     * @inheritdoc ITreasury
     */
    function startErc20Presale(address token, uint256 _duration) external override {
        PresaleInfo storage presaleInfo = s_presaleInfo[token];

        if (presaleInfo.owner != msg.sender) {
            revert Treasury__CallerNotOwner();
        }

        if (presaleInfo.status != PresaleStatus.PENDING) {
            revert Treasury__PresaleStartError();
        }
        presaleInfo.startTime = block.timestamp;
        presaleInfo.endTime = block.timestamp + _duration;
        presaleInfo.status = PresaleStatus.ACTIVE;

        emit PresaleStarted(token, presaleInfo.endTime);
    }

    /**
     * @inheritdoc ITreasury
     */
    function cancelErc20Presale(address token) external override {
        PresaleInfo storage presaleInfo = s_presaleInfo[token];

        if (presaleInfo.owner != msg.sender) {
            revert Treasury__CallerNotOwner();
        }

        if (presaleInfo.status != PresaleStatus.PENDING) {
            revert Treasury__PresaleCannotBeCancelled();
        }

        delete s_presaleInfo[token];
        delete s_tokenInfo[token];

        SafeTransferLib.safeTransfer(presaleInfo.tokenInfo.token, msg.sender, presaleInfo.tokenInfo.amount);
        emit PresaleCancelled(token);
    }

    /**
     * @inheritdoc ITreasury
     */
    function buyErc20Presale(address _token, uint256 amount) external payable override checkIsPresaleActive(_token) {
        PresaleInfo storage presaleInfo = s_presaleInfo[_token];
        TokenInfo storage tokenInfo = s_tokenInfo[_token];
        uint256 priceForAmount = amount * tokenInfo.price;

        if (presaleInfo.status != PresaleStatus.ACTIVE) {
            revert Treasury__PresaleNotActive();
        }

        if (msg.value < priceForAmount) {
            revert Treasury__InsufficientFunds();
        }

        presaleInfo.raisedAmount += priceForAmount;
        tokenInfo.soldAmount += amount;
        s_userPurchasedTokens[_token][msg.sender] += amount;
        uint256 refund = msg.value - priceForAmount;

        if (refund > 0) {
            SafeTransferLib.safeTransferETH(msg.sender, refund);
        }

        emit PresaleTokenBought(_token, amount, msg.sender);
    }

    /**
     * @inheritdoc ITreasury
     */
    function sellErc20Presale(address _token, uint256 _amount) external override checkIsPresaleActive(_token) {
        PresaleInfo storage presaleInfo = s_presaleInfo[_token];
        TokenInfo storage tokenInfo = s_tokenInfo[_token];

        if (presaleInfo.status != PresaleStatus.ACTIVE) {
            revert Treasury__PresaleNotActive();
        }

        if (s_userPurchasedTokens[_token][msg.sender] < _amount) {
            revert Treasury__InsufficientFunds();
        }

        uint256 priceForAmount = _amount * tokenInfo.price;
        presaleInfo.raisedAmount -= priceForAmount;
        tokenInfo.soldAmount -= _amount;
        s_userPurchasedTokens[_token][msg.sender] -= _amount;

        uint256 amountToSend = PresaleUtils.calculateAmountWithFee(priceForAmount);
        SafeTransferLib.safeTransferETH(msg.sender, amountToSend);

        emit PresaleTokenSold(_token, _amount, msg.sender);
    }

    /**
     * @inheritdoc ITreasury
     */
    function previewPresalePrice(uint256 _tokenAmount, uint256 _amountToRaise)
        external
        pure
        override
        returns (uint256 tokenPrice)
    {
        return PresaleUtils.calculatePresalePrice(_tokenAmount, _amountToRaise);
    }

    /**
     * @inheritdoc ITreasury
     */
    function getPresaleInfo(address token) external view override returns (PresaleInfo memory) {
        return s_presaleInfo[token];
    }

    /**
     * @inheritdoc ITreasury
     */
    function getTokenInfo(address token) external view override returns (TokenInfo memory) {
        return s_tokenInfo[token];
    }

    /**
     * @inheritdoc ITreasury
     */
    function getUserPurchasedTokens(address user, address token) external view override returns (uint256) {
        return s_userPurchasedTokens[token][user];
    }
}
