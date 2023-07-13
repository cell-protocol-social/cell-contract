// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../contracts/ExpirePromptSBT.sol";


contract ExpirePromptSBTTest is Test {
    ExpirePromptSBT public promptSBT;

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    function setUp() public {
        promptSBT = new ExpirePromptSBT();
        promptSBT.initialize("Prompt-A SBT", "PPT-A", "https://cell.xyz/", admin);
    }

    function test_Mint_ByOwner() public {
        uint256 id = promptSBT.totalSupply() + 1;
        promptSBT.mint(alice, id, "https://cell.xyz/001");

        assertEq(promptSBT.ownerOf(id), alice);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/001");
        assertEq(promptSBT.balanceOf(alice), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(alice, 0), id);

        id = promptSBT.totalSupply() + 1;
        promptSBT.mint(bob, id, "https://cell.xyz/002");

        assertEq(promptSBT.ownerOf(id), bob);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/002");
        assertEq(promptSBT.balanceOf(bob), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(bob, 0), id);
    }

    function test_Mint_ByTrust() public {
        vm.prank(admin);
        uint256 id = promptSBT.totalSupply() + 1;
        promptSBT.mint(alice, id, "https://cell.xyz/001");

        assertEq(promptSBT.ownerOf(id), alice);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/001");
        assertEq(promptSBT.balanceOf(alice), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(alice, 0), id);

        id = promptSBT.totalSupply() + 1;
        promptSBT.mint(bob, id, "https://cell.xyz/002");

        assertEq(promptSBT.ownerOf(id), bob);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/002");
        assertEq(promptSBT.balanceOf(bob), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(bob, 0), id);
    }

    function test_MintExpire() public {
        uint256 id = promptSBT.totalSupply() + 1;
        uint256 expireAt = block.timestamp + 100;
        promptSBT.mint(alice, id, "https://cell.xyz/001", expireAt);

        assertEq(promptSBT.ownerOf(id), alice);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/001");
        assertEq(promptSBT.balanceOf(alice), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(alice, 0), id);
        assertEq(promptSBT.expireOf(id),expireAt );
        assertEq(promptSBT.isExpire(id), false);

        vm.warp(expireAt + 100);
        assertEq(promptSBT.expireOf(id), expireAt);
        assertEq(promptSBT.isExpire(id), true);
    }

    function test_Renew() public {
        uint256 id = promptSBT.totalSupply() + 1;
        uint256 expireAt = block.timestamp + 100;
        promptSBT.mint(alice, id, "https://cell.xyz/001", expireAt);

        assertEq(promptSBT.ownerOf(id), alice);
        assertEq(promptSBT.tokenURI(id), "https://cell.xyz/001");
        assertEq(promptSBT.balanceOf(alice), 1);
        assertEq(promptSBT.tokenOfOwnerByIndex(alice, 0), id);
        assertEq(promptSBT.expireOf(id),expireAt );
        assertEq(promptSBT.isExpire(id), false);

        vm.warp(expireAt + 100);
        assertEq(promptSBT.expireOf(id), expireAt);
        assertEq(promptSBT.isExpire(id), true);

        uint256 newExpireAt = block.timestamp + 100;
        promptSBT.renew(id, "https://cell.xyz/new001", newExpireAt);
        assertEq(promptSBT.ownerOf(id), alice);
        assertEq(promptSBT.balanceOf(alice), 1);
        assertEq(promptSBT.expireOf(id), newExpireAt);
        assertEq(promptSBT.isExpire(id), false);
    }

    function test_Burn() public {
        test_Mint_ByTrust();

        assertEq(promptSBT.totalSupply(), 2);

        vm.prank(alice);
        promptSBT.burn(1);

        assertEq(promptSBT.totalSupply(), 1);
        assertEq(promptSBT.balanceOf(alice), 0);
        assertEq(promptSBT.tokenOfOwnerByIndex(bob, 0), 2);
    }
}