// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISBTsFactory {
    /**
     * @notice Create new SBT contract
     * 
     * @param name_ The SBT name
     * @param symbol_ The SBT symbol
     * @param baseTokenURI_ The base token URI
     */
    function createNewSBT(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address ownership
    ) external returns (address);

    /**
     * @notice Add SBT contract to valid list
     * 
     * @param sbtContract The SBT contract address
     */
    function addSBTContract(address sbtContract) external;

    /**
     * @notice Make SBT contract invalid
     * 
     * @param sbtContract The SBT contract address
     */
    function removeSBTContract(address sbtContract) external;

    /**
     * @notice Batch Mint SBTs 
     * 
     * @param sbtAddrs The SBTs contract addresses
     * @param tokenURIs The token URIs
     * @param deadline The deadline of signature
     * @param signature The signature
     */
    function batchMint(
        address[] memory sbtAddrs, 
        string[] memory tokenURIs, 
        uint256 deadline, 
        bytes memory signature
    ) external;

    /**
     * @notice Batch mint SBTs has expire time
     * 
     * @param sbtAddrs The SBTs contract addresses
     * @param tokenURIs The token URIs
     * @param expireTimes The expire timestamps
     * @param deadline The deadline of signature
     * @param signature The signature
     */
    function batchMint(
        address[] memory sbtAddrs, 
        string[] memory tokenURIs, 
        uint256[] memory expireTimes,
        uint256 deadline, 
        bytes memory signature
    ) external;

    /**
     * @notice Batch burn user's SBTs
     * 
     * @param sbtAddrs The SBTs contract addresses
     * @param ids The token ids
     */
    function batchBurn(address[] memory sbtAddrs, uint256[] memory ids) external;

    /**
     * @notice Set trust signer address for signature verification
     * 
     * @param trustSigner_ The trust signer address
     */
    function setTrustSigner(address trustSigner_) external;

    /**
     * @notice Get the signature nonce of the user
     * 
     * @param to The user address
     * @return the signature nonce of the user
     */
    function getSigNonce(address to) external view returns (uint256);

    /**
     * @notice Check if the SBT contract is valid
     * 
     * @param sbtContract SBT contract address
     * @return true if the SBT contract is valid
     */
    function isValidSBTContract(address sbtContract) external view returns (bool);
}