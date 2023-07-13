// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../interfaces/IERC5192.sol';

/**
 * @title BaseSBT
 * @notice Base SBT contract with upgradeable
 */
contract BaseSBT is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    IERC5192
{
    string internal _baseTokenURI;
    bool internal _transferable;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Error messages for require statements
    error NotTransferable();
    error NotOwnerOrApproval();
    error NotApprovedOrOwnerOf();

    modifier onlyTransferable() {
        if (_transferable != true) revert NotTransferable();
        _;
    }

    function __BaseSBT_init(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Ownable_init();
        _baseTokenURI = baseTokenURI_;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Burn a token by the owner of token
     * 
     * @param tokenId The token ID to burn
     */
    function burn(uint256 tokenId) external virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotApprovedOrOwnerOf();
        _burn(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
        super.safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setBaseTokenURI(string calldata newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    function setTransferable(bool transferable_) external onlyOwner {
        _transferable = transferable_;
    }

    /*//////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable) 
        returns (bool) 
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function transferable() external view returns (bool) {
        return _transferable;
    }

    function locked(uint256 tokenId) external view override returns (bool) {
        if (_transferable) {
            return false;
        }
        return true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        // string memory base = _baseURI();

        // // If there is no base URI, return the token URI.
        // if (bytes(base).length == 0) {
        //     return _tokenURI;
        // }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            // return string(abi.encodePacked(base, _tokenURI));
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal virtual {
        _requireMinted(tokenId);
        _tokenURIs[tokenId] = tokenURI_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
