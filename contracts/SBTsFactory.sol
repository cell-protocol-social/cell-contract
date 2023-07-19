// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./interfaces/ISBTsFactory.sol";
import "./ExpirePromptSBT.sol";

contract SBTsFactory is Initializable, OwnableUpgradeable, PausableUpgradeable, ISBTsFactory {
    using ECDSAUpgradeable for bytes32;
    uint8 public constant VERSION = 1;

    address public trustSigner;
    mapping(address => uint256) internal _sigNonces;
    address[] public sbtContracts;
    mapping(address => bool) internal _validSbtContracts;

    event NewSBTContract(uint256 indexed idx, address indexed sbtContract);

    error InvalidSignature();
    error ExpiredSignature();
    error InvalidNonce();
    error InvalidContract();
    error ContractExist();
    error InvalidBatch();
    error InvalidExpireArg();
    error InvalidLength();
    error InvalidZeroAddress();

    function initialize(address trustSigner_) initializer external {
        __Ownable_init();
        __Pausable_init();
        trustSigner = trustSigner_;
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function createNewSBT(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address ownership
    ) external override onlyOwner returns (address) {
        ExpirePromptSBT sbt = new ExpirePromptSBT();
        sbt.initialize(name_, symbol_, baseTokenURI_, address(this));
        sbt.transferOwnership(ownership);

        sbtContracts.push(address(sbt));
        _validSbtContracts[address(sbt)] = true;

        emit NewSBTContract(sbtContracts.length - 1, address(sbt));
        return address(sbt);
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function addSBTContract(address sbtContract) external override onlyOwner {
        if (sbtContract == address(0)) revert InvalidContract();
        if (_validSbtContracts[sbtContract]) revert ContractExist();

        sbtContracts.push(sbtContract);
        _validSbtContracts[sbtContract] = true;

        emit NewSBTContract(sbtContracts.length - 1, address(sbtContract));
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function removeSBTContract(address sbtContract) external override onlyOwner {
        if (sbtContract == address(0)) revert InvalidContract();
        if (!_validSbtContracts[sbtContract]) revert InvalidContract();

        _validSbtContracts[sbtContract] = false;
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function batchMint(
        address[] memory sbtAddrs, 
        string[] memory tokenURIs, 
        uint256 deadline, 
        bytes memory signature
    ) external override whenNotPaused {
        if (sbtAddrs.length == 0 || tokenURIs.length == 0) revert InvalidLength();
        if (sbtAddrs.length != tokenURIs.length) revert InvalidBatch();
        unchecked {
            _sigNonces[msg.sender]++;
        }
        _requireTrustSigner(address(this), msg.sender, _sigNonces[msg.sender], deadline, signature);

        for (uint256 i = 0; i < sbtAddrs.length; i++) {
            if (!_validSbtContracts[sbtAddrs[i]]) revert InvalidContract();

            ExpirePromptSBT sbt = ExpirePromptSBT(sbtAddrs[i]);
            sbt.mint(msg.sender, tokenURIs[i]);
        }
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function batchMint(
        address[] memory sbtAddrs, 
        string[] memory tokenURIs, 
        uint256[] memory expireTimes,
        uint256 deadline, 
        bytes memory signature
    ) external override whenNotPaused {
        if (sbtAddrs.length == 0) revert InvalidLength();
        if (sbtAddrs.length != tokenURIs.length) revert InvalidBatch();
        if (sbtAddrs.length != expireTimes.length) revert InvalidBatch();
        unchecked {
            _sigNonces[msg.sender]++;
        }
        _requireTrustSigner(address(this), msg.sender, _sigNonces[msg.sender], deadline, signature);

        for (uint256 i = 0; i < sbtAddrs.length; i++) {
            if (!_validSbtContracts[sbtAddrs[i]]) revert InvalidContract();
            if (expireTimes[i] < block.timestamp) revert InvalidExpireArg();

            ExpirePromptSBT sbt = ExpirePromptSBT(sbtAddrs[i]);
            sbt.mint(msg.sender, tokenURIs[i], expireTimes[i]);
        }
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function batchBurn(address[] memory sbtAddrs, uint256[] memory ids) external override {
        if (sbtAddrs.length == 0) revert InvalidLength();
        if (sbtAddrs.length != ids.length) revert InvalidBatch();

        for (uint256 i = 0; i < sbtAddrs.length; i++) {
            if (!_validSbtContracts[sbtAddrs[i]]) revert InvalidContract();

            ExpirePromptSBT sbt = ExpirePromptSBT(sbtAddrs[i]);
            sbt.burnFrom(msg.sender, ids[i]);
        }
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function setTrustSigner(address trustSigner_) external override onlyOwner {
        if (trustSigner_ == address(0)) revert InvalidZeroAddress();
        trustSigner = trustSigner_;
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function getSigNonce(address to) external view override returns (uint256) {
        return _sigNonces[to];
    }

    /**
     * @inheritdoc ISBTsFactory
     */
    function isValidSBTContract(address sbtContract) external view override returns (bool) {
        return _validSbtContracts[sbtContract];
    }

    function lengthOfSBTs() external view returns (uint256) {
        return sbtContracts.length;
    }

    function _requireTrustSigner(
        address contractAddress_,
        address to_, 
        uint256 sigNonces_,
        uint256 deadline_, 
        bytes memory signature_
    ) internal view virtual {
        if (deadline_ <= block.timestamp) revert ExpiredSignature();
        bytes32 hash = keccak256(abi.encodePacked(contractAddress_, to_, sigNonces_, deadline_));
        bytes32 ethHash = hash.toEthSignedMessageHash();
        if (ethHash.recover(signature_) != trustSigner) revert InvalidSignature();
    }
}