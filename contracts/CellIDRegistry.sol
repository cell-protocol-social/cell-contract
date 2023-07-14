// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';

import './interfaces/ICellIDRegistry.sol';

/**
 * @title CellIDRegistry
 * @notice Cell ID with a SBT token
 *         each address can only hold one cell ID
 *         user can burn cell ID by the owner and mint a new one
 *         a cell ID can mint by itself or be minted by the admin-role caller
 */
contract CellIDRegistry is
    ICellIDRegistry,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable
{
    uint8 public constant VERSION = 1;
    uint256 private _tokenIdCounter;
    bool private _transferable;
    address public resolveController;

    event SetTransferable(bool transferable);
    event SetController(address indexed controller);

    error NotRepeatRegister();
    error NotTransferable(); 
    error NotApprovedOrOwnerOf();
    error NotAdminOrSelf(); 
    error InvalidZeroAddress();

    modifier onlyTransferable() {
        if (!_transferable) revert NotTransferable();
        _;
    }

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __Pausable_init();
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @inheritdoc ICellIDRegistry
     */
    function register(address to) external override whenNotPaused {
        if (
            _msgSender() == to || 
            _msgSender() == owner() ||
            _msgSender() == resolveController
        ) {
            if (balanceOf(to) > 0) revert NotRepeatRegister();

            unchecked {
                _tokenIdCounter++;
            }
            _safeMint(to, _tokenIdCounter);
        } else {
            revert NotAdminOrSelf();
        }
    }

    /**
     * @inheritdoc ICellIDRegistry
     */
    function burn(uint256 tokenId) external override whenNotPaused {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotApprovedOrOwnerOf();
        _burn(tokenId);
    }

    /**
     * @notice Set transferable
     *
     * @param transferable_ The bool transferable
     */
    function setTransferable(bool transferable_) external onlyOwner {
        _transferable = transferable_;

        emit SetTransferable(transferable_);
    }

    /**
     * @notice Set controller
     * @param controller_ The address of the controller
     */
    function setController(address controller_) external onlyOwner {
        if (controller_ == address(0)) revert InvalidZeroAddress();
        resolveController = controller_;

        emit SetController(controller_);
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
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
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
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
        super.safeTransferFrom(from, to, tokenId, '');
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
    ) public override(IERC721Upgradeable, ERC721Upgradeable) onlyTransferable {
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

    /**
     * @inheritdoc ICellIDRegistry
     */
    function idOf(address to) external view override returns (uint256) {
        if (balanceOf(to) > 0) {
            return tokenOfOwnerByIndex(to, 0);
        } else {
            return 0;
        }
    }
}
