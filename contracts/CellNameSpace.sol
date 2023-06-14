// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC721Upgradeable, ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import {ICellNameSpace} from "./interfaces/ICellNameSpace.sol";


error InvalidZeroAddress();
error NameInvalid();
error NameRegisted();
error NotOwner();


contract CellNameSpace is ICellNameSpace, OwnableUpgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable {
    
    // store name info
    struct MetaData {
        string name;
        bytes32 nameHash;
        uint256 creatAt;
    }

    uint256 public constant MAX_HANDLE_LENGTH = 1024;
    uint256 internal _tokenIdCounter;

    mapping(bytes32 => uint256) public idByNameHash;
    mapping(uint256 => MetaData) public metaById;

    function initialize(string memory name_, string memory symbol_) initializer external {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function register(address to_, string memory name_) external override whenNotPaused {
        if (to_ == address(0)) revert InvalidZeroAddress();
        if (!isValid(name_)) revert NameInvalid();
        if (isExist(name_)) revert NameRegisted();
        
        bytes32 nameHash = keccak256(bytes(name_));
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        idByNameHash[nameHash] = tokenId;
        metaById[tokenId] = MetaData(name_, nameHash, block.timestamp);

        _safeMint(to_, tokenId);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) revert NotOwner();
        super._burn(tokenId);
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function isValid(string memory name_) public pure override returns (bool) {
        bytes memory byteName = bytes(name_);
        if (byteName.length == 0 || byteName.length > MAX_HANDLE_LENGTH) {
            return false;
        }

        uint256 byteNameLength = byteName.length;
        for (uint256 i = 0; i < byteNameLength; ) {
            if (
                (byteName[i] < '0' ||
                    byteName[i] > 'z' ||
                    (byteName[i] > '9' && byteName[i] < 'a')) &&
                byteName[i] != '.' &&
                byteName[i] != '-' &&
                byteName[i] != '_'
            ) {
                return false;
            } else {
                ++i;
            }
        }

        return true;
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function isExist(string memory name_) public view override returns (bool) {
        bytes32 nameHash = keccak256(bytes(name_));
        return idByNameHash[nameHash] != 0;
    }
}