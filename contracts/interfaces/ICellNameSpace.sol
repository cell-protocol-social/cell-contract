// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @notice The interface of Cell NameSpace
 *         An ERC-721 NFT contract that manages the ownership of cell names.
 *         The name strings must be unique and not registered and must be valid.
 *         The name strings must be lowercase and length within [3, 20].
 *         The name strings must be end with ".cell" suffix.
 */
interface ICellNameSpace is IERC721EnumerableUpgradeable {

    /**
     * @notice register a name strings to the caller
     *         the name strings must be unique and not registered and must be valid, 
     *         e.g. "google" not be register a unknow address, 
     *         so the caller must has a signature from trust signer who make sure the name strings is valid.
     *         the signature combine with the address of name owner and the deadline timestamp.
     *         the payable value must be equal or greater than the current price.
     * 
     * @param name The name strings
     * @param deadline The deadline timestamp
     * @param signature The trust signature
     */
    function register(string memory name, uint256 deadline, bytes calldata signature) external payable;

    /**
     * @notice Register a name to an address `to` only call from admin-role
     * 
     * @param name The name strings to register
     * @param to The address mint to
     */
    function registerTrust(string memory name, address to) external;

    /**
     * @notice burn the tokenId, tokenId must exist
     * 
     * @param tokenId The uint256 tokenId
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice a name strings has been registered or not
     * 
     * @param name The name strings
     * @return result The boolean of query
     */
    function isExist(string calldata name) external view returns (bool);

    /**
     * @notice Get the name strings by tokenId
     * 
     * @param tokenId The uint256 tokenId
     */
    function nameOf(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Get the tokenId by a name strings
     * 
     * @param name The name strings
     * @return The address of the name strings
     */
    function idByName(string memory name) external view returns (uint256);

}