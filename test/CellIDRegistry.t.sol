// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../contracts/CellIDRegistry.sol";


contract CellIDRegistryTest is Test {
    CellIDRegistry public cellIDRegistry;

    event Register(address indexed owner, uint256 indexed tokenId);

    address alice = address(0x123);
    address bob = address(0x456);

    function setUp() public {
        cellIDRegistry = new CellIDRegistry();
        cellIDRegistry.initialize("Cell DID", "CELLID");
    }

    function testRegister() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Register(alice, 1);
        cellIDRegistry.register();
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(alice, 0), 1);

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Register(bob, 2);
        cellIDRegistry.register();
        assertEq(cellIDRegistry.tokenOfOwnerByIndex(bob, 0), 2);
    }

    function testCannotRegisterTwice() public {
        vm.startPrank(alice);
        cellIDRegistry.register();

        vm.expectRevert(IDAlreadyRegisted.selector);
        cellIDRegistry.register();
        vm.stopPrank();

        assertEq(cellIDRegistry.balanceOf(alice), 1);
    }

    // can not transferable
    function testCannotTransferable() public {
        vm.prank(alice);
        cellIDRegistry.register();

        vm.expectRevert(NotTransferable.selector);
        cellIDRegistry.transferFrom(alice, bob, 1);
    }

}
