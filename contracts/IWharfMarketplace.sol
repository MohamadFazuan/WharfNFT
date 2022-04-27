// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWharfMarketplace {
    /**
     * @dev Set token selling price.
     * @param tokenId Token ID.
     * @param price Token selling price.
     */
    function setSalePrice(uint256 tokenId, uint256 price) external;

    /**
     * @dev Cancel pending offer when token is burn.
     * @param tokenId Token ID.
     */
    function tokenBurn(uint256 tokenId) external;
}
