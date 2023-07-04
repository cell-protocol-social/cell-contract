// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

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
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string internal _baseTokenURI;
    bool internal _transferable;
    CountersUpgradeable.Counter internal _tokenIdCounter;

    /// @dev Error messages for require statements
    error NotTransferable();

    modifier whenTransferable() {
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) whenTransferable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721Upgradeable, ERC721Upgradeable) whenTransferable {
        super.safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(IERC721Upgradeable, ERC721Upgradeable) whenTransferable {
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
    function transferable() external view returns (bool) {
        return _transferable;
    }

    function locked(uint256 tokenId) external view override returns (bool) {
        if (_transferable) {
            return false;
        }
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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
