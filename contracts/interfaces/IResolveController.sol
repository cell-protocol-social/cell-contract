// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IResolveController {
    /**
     * @notice Un-register caller to register a Cell ID and Cell Name
     * 
     * @param name The name to register
     * @param deadline The deadline of the signature
     * @param signature The signature
     */
    function register(string calldata name, uint256 deadline, bytes calldata signature) external;

    /**
     * @notice Register a Cell ID and Cell Name for others only by the owner
     * 
     * @param name The name to register
     * @param to The address to register
     */
    function registerTrust(string calldata name, address to) external;

    /**
     * @notice Binding a Cell ID to a Cell Name
     * 
     * @param cellId The cell ID
     * @param nameId The name ID to binding to the Cell ID
     */
    function binding(uint256 cellId, uint256 nameId) external;

    /**
     * @notice Resolve the caller address to get it's cell name string
     *         if not binding or Name-NFT had transfered, return ""
     * 
     * @param to address of the resolved
     * @return address of the name
     */
    function resolveAddress(address to) external view returns (string memory);

    /**
     * @notice Resolve the name string to the owner address
     * 
     * @param fname The full name strings
     * @return address of the name owner
     */
    function resolveName(string memory fname) external view returns (address);
}