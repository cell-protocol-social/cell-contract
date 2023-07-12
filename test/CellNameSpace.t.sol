// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";
import "../contracts/CellNameSpace.sol";

contract CellNameSpaceTest is Test {
    CellNameSpace nameSpace;

    address treasury = address(0x01);
    address alice = address(0x459A0136E53B122e902f8bC9f13154c53C43aBF5);
    address bob = address(0x02);
    // address trustSigner = address(0x14791697260e4c9a71f18484c9f997b308e59325);
    address trustSigner = address(0x075dfeFc3E9A7dE0F170DB484dB62C76bBbcb865);
    address controller = address(0x03);
    uint256 fee = 0.01 ether;
    
    address to = address(0x459A0136E53B122e902f8bC9f13154c53C43aBF5);
    string name = "0xalice";
    string fullname = "0xalice.cell";
    uint256 deadline = 1691716743;
    bytes signature = hex"5c6e518124b664de4c76d9842459e34c3a07dcc34b5f7378ca1e9151205e251777b8f5de3e24531a639d1cd9349fa104bcf760f163131f10366602d970c8cd111b";
    uint256 nameOfTokenId = 47440327085544000406611535457825476443541695228759988416483712289127719794102;
    address contractAddress = address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f);

    function setUp() public {
        nameSpace = new CellNameSpace();
        nameSpace.initialize("Cell NameSpace", "CNAME", treasury, trustSigner);
        // console.log("nameSpace: %s", address(nameSpace));
        fee = nameSpace.fee();
    }

    function test_Signature() public {
        bytes32 hash = keccak256(abi.encodePacked(contractAddress, alice, name, deadline));
        assertEq(ECDSAUpgradeable.recover(hash, signature), trustSigner);
    }

    function test_Register() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(nameSpace.balanceOf(alice), 1);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), nameOfTokenId);
        assertEq(nameSpace.nameOf(nameOfTokenId), fullname);
        assertEq(nameSpace.idByNameHash(keccak256(bytes("alice.cell"))), 0);
        assertEq(nameSpace.isExist(fullname), true);
    }

    function test_RegisterTrust_Owner() public {
        nameSpace.registerTrust(name, alice);

        assertEq(nameSpace.balanceOf(alice), 1);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), nameOfTokenId);
        assertEq(nameSpace.nameOf(nameOfTokenId), fullname);
        assertEq(nameSpace.idByNameHash(keccak256(bytes("alice.cell"))), 0);
        assertEq(nameSpace.isExist(fullname), true);
    }

    function test_RegisterTrust_Controller() public {
        nameSpace.setController(controller);
        vm.prank(controller);
        nameSpace.registerTrust(name, alice);
        
        assertEq(nameSpace.balanceOf(alice), 1);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), nameOfTokenId);
        assertEq(nameSpace.nameOf(nameOfTokenId), fullname);
        assertEq(nameSpace.idByNameHash(keccak256(bytes("alice.cell"))), 0);
        assertEq(nameSpace.isExist(fullname), true);
    }

    function test_Burn() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);
        vm.prank(alice);
        nameSpace.burn(nameOfTokenId);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.isExist(fullname), false);
        assertEq(nameSpace.totalSupply(), 0);
    }

    function test_TransferFrom() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);

        vm.prank(alice);
        nameSpace.transferFrom(alice, bob, nameOfTokenId);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.balanceOf(bob), 1);
    }

    function test_Revert_Register_InsufficientFunds() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(bytes4(keccak256("InsufficientFunds()")));
        nameSpace.register(name, deadline, signature);
    }

    function test_Revert_Register_Exist() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);

        vm.prank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(bytes4(keccak256("NotRepeatRegister()")));
        nameSpace.register{value: fee}(name, deadline, signature);
    }

    function test_Revert_Register_InvalidName() public {
        vm.expectRevert(bytes4(keccak256("InvalidName()")));
        nameSpace.registerTrust("36", alice);
    }

    function test_Revert_Register_SignatureExpire() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(bytes4(keccak256("SignatureExpired()")));
        nameSpace.register{value: fee}(name, 0, signature);
    }

    function test_Revert_Register_InvalidSignature() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        vm.expectRevert(bytes4(keccak256("InvalidSignature()")));
        nameSpace.register{value: fee}("errorName", deadline, signature);
    }
    
    // function test_Revert_Signature_To() public {
    //     bytes32 hash = keccak256(abi.encodePacked(contractAddress, bob, name, deadline));
    //     assertEq(ECDSAUpgradeable.recover(hash, signature), trustSigner);
    // }

    // function test_Revert_Signature_Name() public {
    //     bytes32 hash = keccak256(abi.encodePacked(contractAddress, to, "errorName", deadline));
    //     assertEq(ECDSAUpgradeable.recover(hash, signature), trustSigner);
    // }

    function test_Withdraw() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(address(contractAddress).balance, fee);
        vm.stopPrank();

        nameSpace.withdraw(fee);
        assertEq(address(treasury).balance, fee);
        assertEq(address(contractAddress).balance, 0);
    }

    function test_Revert_Withdraw_WithdrawTooMuch() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(nameSpace.balanceOf(alice), 1);
        vm.stopPrank();

        vm.expectRevert(bytes4(keccak256("WithdrawTooMuch()")));
        nameSpace.withdraw(fee + 0.01 ether);
    }

}