// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/CellIDRegistry.sol";


contract CellIDRegistryTest is Test {
    CellIDRegistry public cellIDRegistry;

    address alice = vm.addr(1);
    address bob = vm.addr(2);

    function setUp() public {
        cellIDRegistry = new CellIDRegistry();
        cellIDRegistry.initialize("Cell ID", "CID");
    }

    function test_Register() public {
        vm.prank(alice);
        cellIDRegistry.register(alice);
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(alice, 0), 1);

        vm.prank(bob);
        cellIDRegistry.register(bob);
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(bob, 0), 2);
    }

    function test_Burn() public {
        vm.prank(alice);
        cellIDRegistry.register(alice);
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(alice, 0), 1);
        vm.prank(alice);
        cellIDRegistry.burn(1);
        assertEq(cellIDRegistry.balanceOf(alice), 0);
    }

    function test_Revert_Register_NotSelf() public {
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("NotAdminOrSelf()")));
        cellIDRegistry.register(alice);
    }

    function test_Revert_Register_NotRepeatRegister() public {
        vm.prank(alice);
        cellIDRegistry.register(alice);
        vm.expectRevert(bytes4(keccak256("NotRepeatRegister()")));
        cellIDRegistry.register(alice);
    }

    function test_Revert_Burn_NotOwnerOf() public {
        vm.prank(alice);
        cellIDRegistry.register(alice);
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(alice, 0), 1);
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("NotApprovedOrOwnerOf()")));
        cellIDRegistry.burn(1);
    }

    // can not transferable
    function test_Revert_NotTransferable() public {
        vm.prank(alice);
        cellIDRegistry.register(alice);
        vm.expectRevert(bytes4(keccak256("NotTransferable()")));
        cellIDRegistry.transferFrom(alice, bob, 1);
    }

    function test_SetController() public {
        assertEq(cellIDRegistry.resolveController(), address(0));
        cellIDRegistry.setController(alice);
        assertEq(cellIDRegistry.resolveController(), alice);
    }

    function test_IdOf() public {
        assertEq(cellIDRegistry.balanceOf(alice), 0);
        assertEq(cellIDRegistry.idOf(alice), 0);
        vm.prank(alice);
        cellIDRegistry.register(alice);
        assertEq(cellIDRegistry.balanceOf(alice), 1);
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(cellIDRegistry.idOf(alice), 1);
    }
}
