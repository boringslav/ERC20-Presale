// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library PresaleUtils {
    uint256 public constant BIPS = 500;

    error PresaleUtils__DivideByZeroError();
    error PresaleUtils__ErrorCalculatingAmountWithFee();

    /**
     * @param _amount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Calculate the price of the token in the presale based on the token supply and the amount to raise
     */
    function calculatePresalePrice(uint256 _amount, uint256 _amountToRaise)
        external
        pure
        returns (uint256 tokenPrice)
    {
        if (_amount == 0 || _amountToRaise == 0) {
            revert PresaleUtils__DivideByZeroError();
        }
        return (_amountToRaise * 1e18) / _amount;
    }

    /**
     * @param _amount - Amount of ether to withdraw
     * @notice Calculate the amount of ether to withdraw after applying the fee
     */
    function calculateAmountWithFee(uint256 _amount) external pure returns (uint256 fee) {
        if (_amount * BIPS < 10_000) {
            revert PresaleUtils__ErrorCalculatingAmountWithFee();
        }
        return _amount - calculateFee(_amount);
    }

    /**
     * @param _amount Amount of ether to calculate the fee for
     * @notice Calculate the fee for the amount of ether
     */
    function calculateFee(uint256 _amount) public pure returns (uint256 fee) {
        return (_amount * BIPS) / 10_000;
    }
}
