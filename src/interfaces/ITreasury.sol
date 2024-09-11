// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title ITreasury
 * @author  Boringslav
 * @notice  Interface for the Treasury contract
 */
interface ITreasury {
    error Treasury__PresaleAlreadyCreatedError();
    error Treasury__PresaleStartError();
    error Treasury__CallerNotOwner();
    error Treasury__PresaleCannotBeCancelled();

    event PresaleCreated(address indexed token, uint256 indexed price);
    event PresaleStarted(address indexed token, uint256 indexed endTime);
    event PresaleCancelled(address indexed token);

    /**
     * @notice Struct for presale token
     * @param token Address of the token
     * @param price Price of 1 token
     * @param amount Total amount of tokens available for sale
     * @param soldAmount Amount of tokens already sold
     */
    struct TokenInfo {
        address token;
        uint256 price;
        uint256 amount;
        uint256 soldAmount;
    }

    /**
     *
     * @param amountToRaise - Amount of native token to raise
     * @param raisedAmount - Amount of native token raised
     * @param startTime - Start time of the presale
     * @param endTime - End time of the presale
     * @param status - Status of the presale
     * @param owner - Owner of the presale
     */
    struct PresaleInfo {
        uint256 amountToRaise;
        uint256 raisedAmount;
        TokenInfo tokenInfo;
        uint256 startTime;
        uint256 endTime;
        PresaleStatus status;
        address owner;
    }

    /**
     *
     * @param PENDING - Presale is pending (created but not started)
     * @param ACTIVE - Presale is active (started)
     * @param COMPLETED - Presale is completed (ended)
     */
    enum PresaleStatus {
        PENDING,
        ACTIVE,
        COMPLETED
    }

    /**
     * @param _token - Address of the presale token
     * @param _amount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Create a presale for an ERC20 token with the goal of raising a certain amount of native tokens
     * @dev The tokens stay locked in the treasury until the presale ends
     */
    function createErc20Presale(address _token, uint256 _amount, uint256 _amountToRaise) external;

    /**
     * @param _duration - Duration of the presale in seconds
     * @notice Start the presale for the ERC20 token
     */
    function startErc20Presale(address token, uint256 _duration) external;

    /**
     * @param token - Address of the token
     * @notice Cancel the presale for the ERC20 token
     */
    function cancelErc20Presale(address token) external;

    /**
     * @param _tokenAmount -  Amount of tokens available for sale
     * @param _amountToRaise - Amount of native token to raise
     * @notice Preview the price of the token in the presale based on the token supply and the amount to raise
     */
    function previewPresalePrice(uint256 _tokenAmount, uint256 _amountToRaise)
        external
        view
        returns (uint256 tokenPrice);

    /**
     * @notice Get the presale information for a token
     * @param token - Address of the token
     */
    function getPresaleInfo(address token) external view returns (PresaleInfo memory);
    /**
     *  @notice Get the token information
     * @param token - Address of the token
     */
    function getTokenInfo(address token) external view returns (TokenInfo memory);
}
