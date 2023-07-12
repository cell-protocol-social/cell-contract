// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/IResolveController.sol";
import "./interfaces/ICellIDRegistry.sol";
import "./interfaces/ICellNameSpace.sol";

contract ResolveController is Initializable, OwnableUpgradeable, IResolveController {
    ICellIDRegistry public cellIDRegistry;
    ICellNameSpace public cellNameSpace;

    uint8 public constant VERSION = 1;
    string constant SUFFIX = ".cell";
    address public trustSigner;
    mapping(uint256 => uint256) internal _bindingOf;

    event Binding(address indexed to, uint256 indexed cellId, uint256 indexed nameId);
    
    error NotNameOwner();
    error NotIDOwner();
    error SignatureExpired();
    error InvalidSignature();

    function initialize(
        ICellIDRegistry cellIDRegistry_, 
        ICellNameSpace cellNameSpace_, 
        address trustSigner_
    ) external initializer {
        __Ownable_init();
        cellIDRegistry = cellIDRegistry_;
        cellNameSpace = cellNameSpace_;
        trustSigner = trustSigner_;
    }

    /**
     * @inheritdoc IResolveController
     */
    function register(string calldata name, uint256 deadline, bytes calldata signature) external override {
        _requireTrustSigner(address(this), _msgSender(), name, deadline, signature);
        
        if (cellIDRegistry.balanceOf(_msgSender()) == 0) {
            // if not register, register a Cell ID
            cellIDRegistry.register(_msgSender());
        }
        uint256 cellId = cellIDRegistry.idOf(_msgSender());
        string memory fname_ = string.concat(name, SUFFIX);
        uint256 nameId = uint256(keccak256(bytes(fname_)));
        if (!cellNameSpace.isExist(fname_)) {
            cellNameSpace.registerTrust(name, _msgSender());
        } else {
            // if the name is exist, check the owner
            if (cellNameSpace.ownerOf(nameId) != _msgSender()) revert NotNameOwner();
        }

        _bindingOf[cellId] = nameId;

        emit Binding(_msgSender(), cellId, nameId);
    }

    /**
     * @inheritdoc IResolveController
     */
    function registerTrust(string calldata name, address to) external override onlyOwner {
        cellIDRegistry.register(to);
        cellNameSpace.registerTrust(name, to);
        uint256 cellId = cellIDRegistry.idOf(to);
        string memory fname_ = string.concat(name, SUFFIX);
        uint256 nameId = uint256(keccak256(bytes(fname_)));
        _bindingOf[cellId] = nameId;

        emit Binding(_msgSender(), cellId, nameId);
    }

    /**
     * @inheritdoc IResolveController
     */
    function binding(uint256 cellId, uint256 nameId) external override {
        if (cellIDRegistry.ownerOf(cellId) != _msgSender()) revert NotIDOwner();
        if (cellNameSpace.ownerOf(nameId) != _msgSender()) revert NotNameOwner();
        
        _bindingOf[cellId] = nameId;

        emit Binding(_msgSender(), cellId, nameId);
    }

    /**
     * @notice Set trust signer
     * 
     * @param trustSigner_ The address of the trust signer
     */
    function setTrustSigner(address trustSigner_) external onlyOwner {
        trustSigner = trustSigner_;
    }

    /*///////////////////////////////////////////////////////////////
                            View Functions  
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check the full name strings has been registered
     * 
     * @param fname The full name strings
     * @return bool of the name is exist
     */
    function isNameExist(string memory fname) public view returns (bool) {
        return cellNameSpace.isExist(fname);
    }

    /**
     * @notice Get the Cell Name ID of the name string
     * 
     * @param fname The full name strings
     * @return uint256 of the Cell Name ID
     */
    function getNameIdByName(string memory fname) public view returns (uint256) {
        return cellNameSpace.idByName(fname);
    }

    /**
     * @notice Get the Cell ID of the address
     * 
     * @param to address of the resolved
     * @return uint256 of the Cell ID
     */
    function getCellID(address to) public view returns (uint256) {
        return cellIDRegistry.idOf(to);
    }

    /**
     * @notice Get the Cell Name ID of binding to the Cell ID
     * 
     * @param cellId The cell ID
     * @return uint256 of the Cell Name ID
     */
    function getBinding(uint256 cellId) public view returns (uint256) {
        return _bindingOf[cellId];
    }

    /**
     * @inheritdoc IResolveController
     */
    function resolveAddress(address to) external view returns (string memory) {
        string memory name = cellNameSpace.nameOf(_bindingOf[cellIDRegistry.idOf(to)]);
        if (cellNameSpace.ownerOf(cellNameSpace.idByName(name)) != to) {
            return "";
        } else {
            return name;
        }
    }

    /**
     * @inheritdoc IResolveController
     */
    function resolveName(string memory fname) external view returns (address) {
        return cellNameSpace.ownerOf(cellNameSpace.idByName(fname));
    }

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
}