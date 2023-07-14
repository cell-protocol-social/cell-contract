// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/ICellNameSpace.sol";


contract CellNameSpace is 
    ICellNameSpace, 
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable, 
    PausableUpgradeable 
{   
    uint8 public constant VERSION = 1;
    string constant SUFFIX = ".cell";

    address public treasury;
    address public trustSigner;
    address public resolveController;
    uint256 public fee = 0.01 ether;

    // cheap storage tokenId => name(bytes32)
    mapping(uint256 => bytes32) internal _nameOfTokenId;

    event Register(address indexed owner, uint256 indexed tokenId, string name);
    event SetController(address indexed controller);

    error NotZeroAddress();
    error InvalidName();
    error NotRepeatRegister();
    error SignatureExpired();
    error InvalidSignature();
    error NotApprovedOrOwnerOf();
    error NotTrustCaller();
    error InsufficientFunds();
    error WithdrawTooMuch();
    error CallFailed();

    function initialize(
        string memory name_, 
        string memory symbol_,
        address treasury_,
        address trustSigner_
    ) initializer external {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        __Pausable_init();
        treasury = treasury_;
        trustSigner = trustSigner_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function register(string calldata name_, uint256 deadline, bytes calldata signature) external payable override whenNotPaused {
        if (msg.value < fee) revert InsufficientFunds();
        _requireTrustSigner(address(this), _msgSender(), name_, deadline, signature);
        
        _register(name_, _msgSender());
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function registerTrust(string calldata name_, address to_) external override whenNotPaused {
        if (to_ == address(0)) revert NotZeroAddress();
        if (_msgSender() == owner() || _msgSender() == resolveController) {
            _register(name_, to_);
        } else {
            revert NotTrustCaller();
        }
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert NotApprovedOrOwnerOf();

        _nameOfTokenId[tokenId] = bytes32("");
        _burn(tokenId);
    }

    /**
     * @notice Upgrade the treasury address
     * @param treasury_ The address of the treasury
     */
    function setTreasury(address treasury_) external onlyOwner {
        if (treasury_ == address(0)) revert NotZeroAddress();

        treasury = treasury_;
    }

    /**
     * @notice Set controller
     * @param controller_ The address of the controller
     */
    function setController(address controller_) external onlyOwner {
        if (controller_ == address(0)) revert NotZeroAddress();

        resolveController = controller_;
        emit SetController(controller_);
    }

    /**
     * @notice Set trust signer
     * 
     * @param trustSigner_ The address of the trust signer
     */
    function setTrustSigner(address trustSigner_) external onlyOwner {
        if (trustSigner_ == address(0)) revert NotZeroAddress();

        trustSigner = trustSigner_;
    }

    /**
     * @notice Change system base fee
     * 
     * @param fee_ The fee of register
     */
    function changeFee(uint256 fee_) external onlyOwner {
        fee = fee_;
    }

    /**
     * @notice Withdraw the fees within the contract
     * 
     * @param amount The amount of withdrawal
     */
    function withdraw(uint256 amount) external onlyOwner {
        if (address(this).balance < amount) revert WithdrawTooMuch();

        // use call instead of transfer of send to avoid breaking gas changes
        (bool success, ) = treasury.call{value: amount}("");
        if (!success) revert CallFailed();
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions  
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc ICellNameSpace
     */
    function isExist(string memory fname_) public view override returns (bool) {
        uint256 nameHash = uint256(keccak256(bytes(fname_)));
        return _nameOfTokenId[nameHash] != bytes32("");
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function nameOfTokenId(uint256 tokenId) external view override returns (bytes32) {
        return _nameOfTokenId[tokenId];
    }

    /**
     * @inheritdoc ICellNameSpace
     */
    function idOfName(string calldata fname_) external view override returns (uint256) {
        if (isExist(fname_)) {
            return uint256(keccak256(bytes(fname_)));
        } else {
            return 0;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions  
    //////////////////////////////////////////////////////////////*/

    function _requireTrustSigner(
        address contractAddress,
        address to_, 
        string calldata name_,
        uint256 deadline_, 
        bytes calldata signature_
    ) internal view {
        if (deadline_ <= block.timestamp) revert SignatureExpired();
        bytes32 hash = keccak256(abi.encodePacked(contractAddress, to_, name_, deadline_));
        if (ECDSAUpgradeable.recover(hash, signature_) != trustSigner) revert InvalidSignature();
    }

    function _register(string memory name_, address to_) internal {
        if (bytes(name_).length < 4 || bytes(name_).length > 32) revert InvalidName();

        string memory fname_ = string.concat(name_, SUFFIX);
        if (isExist(fname_)) revert NotRepeatRegister();

        uint256 tokenId = uint256(keccak256(bytes(fname_)));
        _nameOfTokenId[tokenId] = bytes32(abi.encodePacked(fname_));
        _safeMint(to_, tokenId);

        emit Register(to_, tokenId, fname_);
    }
}