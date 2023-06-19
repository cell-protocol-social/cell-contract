// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 


contract PromptTag is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
 
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(string memory _tokenURI) public returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function batchMint(string[] memory tokenURIs) external {
        for (uint i = 0; i < tokenURIs.length; i++) {
            mint(tokenURIs[i]);
        }
    }

    /**
     * @notice Burn owner customize tag SBT with tokenId
     * 
     * @param tokenId The SBT tokenId
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function batchBurn(uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        require(from == address(0), "Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}