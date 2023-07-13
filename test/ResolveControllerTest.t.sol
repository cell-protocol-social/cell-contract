// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";
import "../contracts/CellIDRegistry.sol";
import "../contracts/CellNameSpace.sol";
import "../contracts/ResolveController.sol";

contract ResolveControllerTest is Test {
    CellIDRegistry cellIDRegistry;
    CellNameSpace nameSpace;
    ResolveController controller;

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    address treasury = vm.addr(4);

    string name = "0xalice";
    string fullname = "0xalice.cell";
    uint256 fee;

    function _createSign(bytes32 dataHash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, dataHash);
        return abi.encodePacked(r, s, v);
    }

    function _generateTokenId(string memory name_) internal pure returns (uint256 tokenId) {
        string memory fname_ = string.concat(name_, ".cell");
        bytes32 nameHash = keccak256(bytes(fname_));
        tokenId = uint256(nameHash);
    }

    function setUp() public {
        // deploy ID registry
        cellIDRegistry = new CellIDRegistry();
        cellIDRegistry.initialize("Cell ID", "CID");

        // deploy name space
        nameSpace = new CellNameSpace();
        nameSpace.initialize("Cell NameSpace", "CNAME", treasury, admin);
        fee = nameSpace.fee();

        // deploy resolve controller
        controller = new ResolveController();
        controller.initialize(cellIDRegistry, nameSpace, admin);

        // set controller to ID registry and name space
        cellIDRegistry.setController(address(controller));
        nameSpace.setController(address(controller));
    }

    function test_RegisterTrust() public {
        uint256 tokenId = _generateTokenId(name);
        controller.registerTrust(name, alice);

        assertEq(cellIDRegistry.idOf(alice), 1);
        assertEq(nameSpace.ownerOf(tokenId), alice);

        assertEq(controller.isNameExist(fullname), true);
        assertEq(controller.getCellID(alice), 1);
        assertEq(controller.resolveAddress(alice), fullname);
        assertEq(controller.resolveName(fullname), alice);
    }

    function test_Register_InvalidSignature() public {
        vm.prank(alice);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(controller), alice, name, deadline));
        bytes memory signature = _createSign(dataHash);
        vm.expectRevert(bytes4(keccak256("InvalidSignature()")));
        controller.register("errorName", deadline, signature);
    }

    function test_Register_SignatureExpired() public {
        vm.prank(alice);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(controller), alice, name, deadline));
        bytes memory signature = _createSign(dataHash);
        vm.expectRevert(bytes4(keccak256("SignatureExpired()")));
        controller.register(name, 0, signature);
    }

    function test_Register() public {
        vm.prank(alice);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(controller), alice, name, deadline));
        bytes memory signature = _createSign(dataHash);
        controller.register(name, deadline, signature);

        assertEq(controller.isNameExist(fullname), true);
        assertEq(controller.getCellID(alice), 1);
        assertEq(controller.resolveAddress(alice), fullname);
        assertEq(controller.resolveName(fullname), alice);
    }

    function test_Binding() public {
        controller.registerTrust(name, alice);
        cellIDRegistry.register(bob);
        vm.startPrank(alice);
        uint256 tokenId = _generateTokenId(name);
        nameSpace.transferFrom(alice, bob, tokenId);
        assertEq(nameSpace.ownerOf(tokenId), bob);
        vm.stopPrank();

        uint256 bobId = cellIDRegistry.idOf(bob);

        vm.startPrank(bob);
        controller.binding(bobId, tokenId);
        vm.stopPrank();

        assertEq(controller.getBinding(bobId), tokenId);
        assertEq(controller.resolveName(fullname), bob);
    }

    function test_Revert_Binding_NotOwnerOf() public {
        controller.registerTrust(name, alice);
        cellIDRegistry.register(bob);
        uint256 bobId = cellIDRegistry.idOf(bob);
        uint256 tokenId = _generateTokenId(name);
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("NotNameOwner()")));
        controller.binding(bobId, tokenId);
    }
}
