// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./base/BaseSBT.sol";
import "./interfaces/IExpirePromptSBT.sol";

contract ExpirePromptSBT is IExpirePromptSBT, BaseSBT {
    address public trustFactory;
    uint256 private _tokenIdCounter;
    mapping(uint256 => uint256) internal _expireOfTokenId;

    error NotOwnerOf();
    error NotOwnerOrFromTrust();
    error InvalidZeroAddress();

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address trustFactory_
    ) initializer external {
        __BaseSBT_init(name_, symbol_, baseTokenURI_);
        trustFactory = trustFactory_;
    }

    /**
     * @inheritdoc IExpirePromptSBT
     */
    function mint(address to, string memory _tokenURI) external override virtual {
        _requireOwnerOrFromTrust(); 
        _tokenIdCounter++;
        _mintTrust(to, _tokenIdCounter, _tokenURI);
    }
    
    /**
     * @inheritdoc IExpirePromptSBT
     */
    function mint(address to, string memory _tokenURI, uint256 expireTime) external override virtual {
        _requireOwnerOrFromTrust(); 
        _tokenIdCounter++;
        _expireOfTokenId[_tokenIdCounter] = expireTime;
        _mintTrust(to, _tokenIdCounter, _tokenURI);
    } 

    function burn(uint256 tokenId) external override virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotApprovedOrOwnerOf();

        _expireOfTokenId[tokenId] = 0;
        _burn(tokenId);
    }

    /**
     * @inheritdoc IExpirePromptSBT
     */
    function burnFrom(address to, uint256 tokenId) external override virtual {
        if (to != ownerOf(tokenId)) revert NotOwnerOf();
        if (
            !_isApprovedOrOwner(_msgSender(), tokenId) && 
            !(_msgSender() == trustFactory)
        ) revert NotApprovedOrOwnerOf();

        _expireOfTokenId[tokenId] = 0;
        _burn(tokenId);
    }

    /**
     * @inheritdoc IExpirePromptSBT
     */
    function renew(uint256 tokenId, string memory _tokenURI, uint256 expireTime) external override virtual {
        _requireOwnerOrFromTrust();
        _expireOfTokenId[tokenId] = expireTime;
        _setTokenURI(tokenId, _tokenURI);
    }

    function setTrustFactory(address trustFactory_) external onlyOwner {
        if (trustFactory_ == address(0)) revert InvalidZeroAddress();
        trustFactory = trustFactory_;
    }

    function expireOf(uint256 tokenId) external view returns (uint256) {
        return _expireOfTokenId[tokenId];
    }

    function isExpire(uint256 tokenId) external view returns (bool) {
        return _expireOfTokenId[tokenId] != 0 && _expireOfTokenId[tokenId] <= block.timestamp;
    }

    function _requireOwnerOrFromTrust() internal view {
        if (
            _msgSender() != owner() &&
            _msgSender() != trustFactory
        ) revert NotOwnerOrFromTrust();
    }

    function _mintTrust(address to, uint256 tokenId, string memory _tokenURI) internal virtual {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}