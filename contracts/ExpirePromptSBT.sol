// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./base/BaseSBT.sol";

interface IExpirePromptSBT {

    /**
     * @notice Mint a new token only by the owner or the trust singer
     *         the token will not expire
     * 
     * @param to The address to mint to
     * @param tokenId The token ID to mint
     * @param _tokenURI The token URI of the token ID
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI) external;

    /**
     * @notice Mint a expireTime token only by the owner or the trust singer
     * 
     * @param to The address to mint to
     * @param tokenId The token ID to mint
     * @param _tokenURI The token URI of the token ID
     * @param expireTime The expire time of the token ID
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI, uint256 expireTime) external;

    /**
     * @notice Renew a expireTime token only by the owner or the trust singer
     * 
     * @param tokenId The token ID to renew
     * @param _tokenURI The token URI of the token ID
     * @param expireTime The expire time of the token ID to renew
     */
    function renew(uint256 tokenId, string memory _tokenURI, uint256 expireTime) external;

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

contract ExpirePromptSBT is IExpirePromptSBT, BaseSBT {
    address public trustSinger;
    mapping(uint256 => uint256) internal _expireOfTokenId;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address trustSinger_
    ) initializer external {
        __BaseSBT_init(name_, symbol_, baseTokenURI_);
        trustSinger = trustSinger_;
    }

    /**
     * @inheritdoc IExpirePromptSBT
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI) external override virtual {
        _requireOwnerOrTrustSinger(); 
        _mintTrust(to, tokenId, _tokenURI);
    }
    
    /**
     * @inheritdoc IExpirePromptSBT
     */
    function mint(address to, uint256 tokenId, string memory _tokenURI, uint256 expireTime) external override virtual {
        _requireOwnerOrTrustSinger(); 
        _expireOfTokenId[tokenId] = expireTime;
        _mintTrust(to, tokenId, _tokenURI);
    } 

    /**
     * @inheritdoc IExpirePromptSBT
     */
    function renew(uint256 tokenId, string memory _tokenURI, uint256 expireTime) external override virtual {
        _requireOwnerOrTrustSinger();
        _expireOfTokenId[tokenId] = expireTime;
        _setTokenURI(tokenId, _tokenURI);
    }

    function setTrustSinger(address trustSinger_) external onlyOwner {
        trustSinger = trustSinger_;
    }

    function expireOf(uint256 tokenId) external view returns (uint256) {
        return _expireOfTokenId[tokenId];
    }

    function isExpire(uint256 tokenId) external view returns (bool) {
        return _expireOfTokenId[tokenId] != 0 && _expireOfTokenId[tokenId] <= block.timestamp;
    }

    function _requireOwnerOrTrustSinger() internal view {
        if (
            _msgSender() != owner() &&
            _msgSender() != trustSinger
        ) revert NotOwnerOrApproval();
    }

    function _mintTrust(address to, uint256 tokenId, string memory _tokenURI) internal virtual {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}