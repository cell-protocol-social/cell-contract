// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/CellNameSpace.sol";

contract CellNameSpaceTest is Test {
    CellNameSpace nameSpace;

    address admin = address(0x001);
    address alice = address(0x123);
    address bob = address(0x456);

    function setUp() public {
        nameSpace = new CellNameSpace();
        nameSpace.initialize("Cell NameSpace", "CELL");
    }

    function testRegister() public {
        nameSpace.register(alice, "alice");
        assertEq(nameSpace.ownerOf(0), alice);
        assertEq(nameSpace.idByNameHash(keccak256(bytes("alice"))), 0);
    }

    function testBurn() public {
        nameSpace.register(alice, "alice");
        
        vm.prank(alice);
        nameSpace.burn(0);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.isExist("alice"), false);
    }

}