// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ITreasury} from "./interfaces/ITreasury.sol";
import {PresaleUtils} from "./lib/PresaleUtils.sol";

contract Treasury is ITreasury {
    mapping(address token => PresaleInfo) public s_presaleInfo;
    mapping(address token => TokenInfo) public s_tokenInfo;

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

    function previewPresalePrice(uint256 _tokenAmount, uint256 _amountToRaise)
        external
        pure
        override
        returns (uint256 tokenPrice)
    {
        return PresaleUtils.calculatePresalePrice(_tokenAmount, _amountToRaise);
    }

    function getPresaleInfo(address token) external view override returns (PresaleInfo memory) {
        return s_presaleInfo[token];
    }

    function getTokenInfo(address token) external view override returns (TokenInfo memory) {
        return s_tokenInfo[token];
    }
}
