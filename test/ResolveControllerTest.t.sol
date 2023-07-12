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

    address treasury = address(0x01);
    address alice = address(0x459A0136E53B122e902f8bC9f13154c53C43aBF5);
    address bob = address(0x02);
    // address trustSigner = address(0x14791697260e4c9a71f18484c9f997b308e59325);
    address trustSigner = address(0xD90b85DFbCDde5882565B51b32a8Fd749C13C725);
    // address controller = address(0x03);
    uint256 fee = 0.01 ether;
    
    address to = address(0x459A0136E53B122e902f8bC9f13154c53C43aBF5);
    string name = "0xalice";
    string fullname = "0xalice.cell";
    uint256 deadline = 1691716743;
    bytes signature = hex"e675d4049302dc002a34ce08a2c2eb20f36dd994c27cdff592350951be931fa36dbd17f6fb23dfeb7901c8bc1d889257fcfa57caf49024c95c981dc00802a79f1b";
    uint256 nameOfTokenId = 47440327085544000406611535457825476443541695228759988416483712289127719794102;
    // controller deployed address use to sign
    address contractAddress = address(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a);

    function setUp() public {
        // deploy ID registry
        cellIDRegistry = new CellIDRegistry();
        cellIDRegistry.initialize("Cell ID", "CID");
        // console.log("cellIDRegistry: %s", address(cellIDRegistry));

        // deploy name space
        nameSpace = new CellNameSpace();
        nameSpace.initialize("Cell NameSpace", "CNAME", treasury, trustSigner);
        // console.log("nameSpace: %s", address(nameSpace));
        fee = nameSpace.fee();

        // deploy resolve controller
        controller = new ResolveController();
        controller.initialize(cellIDRegistry, nameSpace, trustSigner);
        // console.log("controller: %s", address(controller));

        // set controller to ID registry and name space
        cellIDRegistry.setController(address(controller));
        nameSpace.setController(address(controller));
    }

    function test_Signature() public {
        bytes32 hash = keccak256(abi.encodePacked(contractAddress, alice, name, deadline));
        assertEq(ECDSAUpgradeable.recover(hash, signature), trustSigner);
    }

    function test_RegisterTrust() public {
        controller.registerTrust(name, alice);

        assertEq(cellIDRegistry.idOf(alice), 1);
        assertEq(nameSpace.ownerOf(nameOfTokenId), alice);
        assertEq(controller.isNameExist(fullname), true);
        assertEq(controller.getCellID(alice), 1);
        assertEq(controller.resolveAddress(alice), fullname);
        assertEq(controller.resolveName(fullname), alice);
    }

    function test_Register_InvalidSignature() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("InvalidSignature()")));
        controller.register("errorName", deadline, signature);
    }

    function test_Register_SignatureExpired() public {
        vm.prank(alice);
        vm.expectRevert(bytes4(keccak256("SignatureExpired()")));
        controller.register(name, 0, signature);
    }

    function test_Register() public {
        vm.prank(alice);
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
        nameSpace.transferFrom(alice, bob, nameOfTokenId);
        assertEq(nameSpace.ownerOf(nameOfTokenId), bob);
        vm.stopPrank();

        uint256 bobId = cellIDRegistry.idOf(bob);

        vm.startPrank(bob);
        controller.binding(bobId, nameOfTokenId);
        vm.stopPrank();

        assertEq(controller.getBinding(bobId), nameOfTokenId);
        assertEq(controller.resolveName(fullname), bob);
    }

    function test_Revert_Binding_NotOwnerOf() public {
        controller.registerTrust(name, alice);
        cellIDRegistry.register(bob);
        uint256 bobId = cellIDRegistry.idOf(bob);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("NotNameOwner()")));
        controller.binding(bobId, nameOfTokenId);
    }
}
