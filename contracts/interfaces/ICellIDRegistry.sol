// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @title ICellIDRegistry
 * @notice Cell ID registry interface
 */
interface ICellIDRegistry is IERC721EnumerableUpgradeable {

    /**
     * @notice Register a cell ID
     * @dev Caller must be the `to` address(mint for self) or only admin-role mint for `to` address
     * 
     * @param to The address to mint to
     */
    function register(address to) external;

    /**
     * @notice Destroys tokenId, tokenId must exist and caller must be owner
     * 
     * @param tokenId The uint256 tokenId
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Get the cell ID of an address
     * @dev If the address has not minted a cell ID, returns 0
     * 
     * @param to The address to mint to
     * @return The uint256 cell ID
     */
    function idOf(address to) external view returns (uint256);

}