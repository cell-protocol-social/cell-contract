// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/CellIDRegistry.sol";

import "../contracts/PromptTag.sol";


contract PromptTagTest is Test {
    PromptTag public promptTag;

    address admin = address(0x001);
    address alice = address(0x123);
    address bob = address(0x456);

    function setUp() public {
        promptTag = new PromptTag("PromptTag", "PROMPT");
    }

    function testMint() public {
        vm.prank(alice);
        promptTag.mint("https://example.com/1");
        assertEq(promptTag.balanceOf(alice), 1);

        vm.prank(alice);
        promptTag.mint("https://example.com/2");
        assertEq(promptTag.balanceOf(alice), 2);

        vm.prank(bob);
        promptTag.mint("https://example.com/3");
        assertEq(promptTag.balanceOf(bob), 1);
    }
}
