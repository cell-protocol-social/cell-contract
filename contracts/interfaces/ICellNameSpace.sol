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
     * @param fname The full name strings with suffix
     * @return result The boolean of query
     */
    function isExist(string calldata fname) external view returns (bool);

    /**
     * @notice Get the name strings by tokenId
     * 
     * @param tokenId The uint256 tokenId
     * @return The full name with bytes32 type
     */
    function nameOfTokenId(uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Get the tokenId by a name strings
     * 
     * @param fname The full name strings with suffix
     * @return The tokenId with uint256
     */
    function idOfName(string memory fname) external view returns (uint256);

}