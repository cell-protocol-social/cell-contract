// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../contracts/base/BaseSBT.sol";

contract PromptSBT is Initializable, BaseSBT, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) public initializer {
        __Pausable_init();
        __BaseSBT_init(name_, symbol_, baseTokenURI_);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function register() external whenNotPaused {
        require(balanceOf(_msgSender()) == 0, "Already_Registed");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
    }

}


contract PromptSBTTest is Test {
    PromptSBT public promptSBT;
    address alice = address(0x123);
    address bob = address(0x456);

    function setUp() public {
        promptSBT = new PromptSBT();
        promptSBT.initialize("Prompt-A SBT", "PPT-A", "https://cell.xyz/");
    }

    function testRegister() public {
        vm.prank(alice);
        promptSBT.register();
        assertEq(promptSBT.tokenOfOwnerByIndex(alice, 0), 1);

        vm.prank(bob);
        promptSBT.register();
        assertEq(promptSBT.tokenOfOwnerByIndex(bob, 0), 2);
    }
}