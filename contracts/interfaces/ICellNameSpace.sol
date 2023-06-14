// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @notice The interface of Cell NameSpace
 *         An ERC-721 NFT contract that manages the ownership of cell names.
 */
interface ICellNameSpace is IERC721Upgradeable {

    /**
     * @notice a name strings is valid or not
     * 
     * @param name The name strings
     * @return result The boolean of query
     */
    function isValid(string memory name) external pure returns (bool);

    /**
     * @notice a name strings has been registered or not
     * 
     * @param name The name strings
     * @return result The boolean of query
     */
    function isExist(string memory name) external view returns (bool);

    /**
     * @notice register a name strings to a address
     * 
     * @param to Receiver address
     * @param name The name strings
     */
    function register(address to, string memory name) external;

}