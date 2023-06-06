// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC721Upgradeable, ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import {ICellIDRegistry} from "./interfaces/ICellIDRegistry.sol";


error IDAlreadyRegisted(); // Cell ID already registered
error NotTransferable(); // Cell ID not transferable
error InvalidTokenId(); // Invalid token id number

/**
 * @title CellIDRegistry
 * @notice Cell ID registry
 */
contract CellIDRegistry is ICellIDRegistry, OwnableUpgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable {
    event SetTransferable(bool transferable);
    event Register(address indexed owner, uint256 indexed tokenId);
    
    uint8 public constant VERSION = 1;
    uint256 private _tokenIdCounter;
    bool private _transferable;

    modifier onlyTransferable() {
        // require(_transferable, "SBT not transferable");
        if (_transferable != true) revert NotTransferable();
        _;
    }

    function initialize(string memory name_, string memory symbol_) initializer external {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __Pausable_init();
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set transferable
     * 
     * @param transferable_ The bool transferable
     */
    function setTransferable(bool transferable_) external onlyOwner {
        _transferable = transferable_;
        emit SetTransferable(transferable_);
    }

    /// @inheritdoc ICellIDRegistry
    function register() external whenNotPaused override {
        if (balanceOf(_msgSender()) > 0) revert IDAlreadyRegisted();

        unchecked {
            ++_tokenIdCounter;
        }
        _safeMint(_msgSender(), _tokenIdCounter);

        emit Register(_msgSender(), _tokenIdCounter);
    }

    /// @inheritdoc ICellIDRegistry
    function burn(uint256 tokenId) external whenNotPaused override {
        if (ownerOf(tokenId) != _msgSender()) revert InvalidTokenId();

        super._burn(tokenId);
    }

    /**** Override super transferable functions ****/

    /**
     * @dev See {IERC721-transferFrom}.
     * @notice Override super transferFrom function to add onlyTransferable modifier
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @notice Override super safeTransferFrom function to add onlyTransferable modifier
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @notice Override super safeTransferFrom function to add onlyTransferable modifier
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyTransferable override(IERC721Upgradeable, ERC721Upgradeable) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /*//////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Get transferable
     */
    function transferable() external view returns (bool) {
        return _transferable;
    }
}