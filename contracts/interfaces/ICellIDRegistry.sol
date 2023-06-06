// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title ICellIDRegistry
 * @author Brooks
 * @notice Cell ID registry interface
 */
interface ICellIDRegistry {
    /**
     * @notice Register a cell ID
     */
    function register() external;

    /**
     * @notice Destroys tokenId, tokenId must exist
     * 
     * @param tokenId The uint256 tokenId
     */
    function burn(uint256 tokenId) external;
}