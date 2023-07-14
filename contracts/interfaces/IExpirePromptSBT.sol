// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IExpirePromptSBT {

    /**
     * @notice Mint a new token only by the owner or the trust singer
     *         the token will not expire
     * 
     * @param to The address to mint to
     * @param _tokenURI The token URI of the token ID
     */
    function mint(address to, string memory _tokenURI) external;

    /**
     * @notice Mint a expireTime token only by the owner or the trust singer
     * 
     * @param to The address to mint to
     * @param _tokenURI The token URI of the token ID
     * @param expireTime The expire time of the token ID
     */
    function mint(address to, string memory _tokenURI, uint256 expireTime) external;

    /**
     * @notice Renew a expireTime token only by the owner or the trust singer
     * 
     * @param tokenId The token ID to renew
     * @param _tokenURI The token URI of the token ID
     * @param expireTime The expire time of the token ID to renew
     */
    function renew(uint256 tokenId, string memory _tokenURI, uint256 expireTime) external;

    /**
     * @notice Burn a token from the trust factory contract or owner
     *         require the to is the owner of the token ID
     * 
     * @param to The address to burn tokenId owner
     * @param tokenId The token ID to burn
     */
    function burnFrom(address to, uint256 tokenId) external;

    /**
     * @notice Get the expire time of the token ID
     * 
     * @param tokenId The token ID to check
     * @return The expire time of the token ID
     */
    function expireOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Check the token ID is expired
     * 
     * @param tokenId The token ID to check
     * @return True if the token ID is expired
     */
    function isExpire(uint256 tokenId) external view returns (bool);
}