// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "forge-std/Test.sol";
import "../contracts/CellNameSpace.sol";

contract CellNameSpaceTest is Test {
    using ECDSA for bytes32;
    CellNameSpace nameSpace;

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    address treasury = vm.addr(4);

    string name = "0xalice";
    string fullname = "0xalice.cell";
    uint256 fee;

    function _createEthSign(bytes32 dataHash) internal pure returns (bytes memory) {
        bytes32 hash = dataHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
        return abi.encodePacked(r, s, v);
    }

    function _generateTokenId(string memory name_) internal pure returns (uint256 tokenId) {
        string memory fname_ = string.concat(name_, ".cell");
        bytes32 nameHash = keccak256(bytes(fname_));
        tokenId = uint256(nameHash);
    }
    
    function setUp() public {
        nameSpace = new CellNameSpace();
        nameSpace.initialize("Cell NameSpace", "CNAME", treasury, admin);
        fee = nameSpace.fee();
    }

    function test_PureSign() public {
        uint256 deadline = block.timestamp + 1000;
        bytes32 hash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(hash);
        
        bytes32 dataHash = hash.toEthSignedMessageHash();
        assertEq(dataHash.recover(signature), admin);
    }

    function test_Default() public {
        assertEq(nameSpace.name(), "Cell NameSpace");
        assertEq(nameSpace.symbol(), "CNAME");
        assertEq(nameSpace.treasury(), treasury);
        assertEq(nameSpace.trustSigner(), admin);
        assertEq(nameSpace.resolveController(), address(0));
        assertEq(nameSpace.fee(), fee);
        assertEq(nameSpace.totalSupply(), 0);
        assertEq(nameSpace.isExist(fullname), false);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.idOfName(fullname), 0);
    }

    function test_Register() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(nameSpace.balanceOf(alice), 1);
        assertEq(address(nameSpace).balance, fee);
        assertEq(alice.balance, 1 ether - fee);

        uint256 tokenId = _generateTokenId(name);
        assertEq(nameSpace.nameOfTokenId(tokenId), bytes32(abi.encodePacked(fullname)));
        assertEq(nameSpace.isExist(fullname), true);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), tokenId);
    }

    function test_RegisterTrust_Owner() public {
        nameSpace.registerTrust(name, alice);

        assertEq(nameSpace.balanceOf(alice), 1);

        uint256 tokenId = _generateTokenId(name);
        assertEq(nameSpace.nameOfTokenId(tokenId), bytes32(abi.encodePacked(fullname)));
        assertEq(nameSpace.isExist(fullname), true);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), tokenId);
    }

    function test_RegisterTrust_Controller() public {
        nameSpace.setController(admin);
        vm.prank(admin);
        nameSpace.registerTrust(name, alice);
        
        assertEq(nameSpace.balanceOf(alice), 1);

        uint256 tokenId = _generateTokenId(name);
        assertEq(nameSpace.nameOfTokenId(tokenId), bytes32(abi.encodePacked(fullname)));
        assertEq(nameSpace.isExist(fullname), true);
        assertEq(nameSpace.tokenOfOwnerByIndex(alice, 0), tokenId);
    }

    function test_Burn() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);
        vm.prank(alice);
        uint256 tokenId = _generateTokenId(name);
        nameSpace.burn(tokenId);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.isExist(fullname), false);
        assertEq(nameSpace.totalSupply(), 0);
    }

    function test_TransferFrom() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);

        vm.prank(alice);
        uint256 tokenId = _generateTokenId(name);
        nameSpace.transferFrom(alice, bob, tokenId);
        assertEq(nameSpace.balanceOf(alice), 0);
        assertEq(nameSpace.balanceOf(bob), 1);
    }

    function test_Revert_Register_InsufficientFunds() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        vm.expectRevert(bytes4(keccak256("InsufficientFunds()")));
        nameSpace.register(name, deadline, signature);
    }

    function test_Revert_Register_Exist() public {
        nameSpace.registerTrust(name, alice);
        assertEq(nameSpace.balanceOf(alice), 1);

        vm.prank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
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
        uint256 deadline = block.timestamp;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        vm.expectRevert(bytes4(keccak256("SignatureExpired()")));
        nameSpace.register{value: fee}(name, 0, signature);
    }

    function test_Revert_Register_InvalidSignature() public {
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        vm.expectRevert(bytes4(keccak256("InvalidSignature()")));
        nameSpace.register{value: fee}("errorName", deadline, signature);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(address(nameSpace).balance, fee);
        vm.stopPrank();

        nameSpace.withdraw(fee);
        assertEq(address(treasury).balance, fee);
        assertEq(address(nameSpace).balance, 0);
    }

    function test_Revert_Withdraw_WithdrawTooMuch() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        uint256 deadline = block.timestamp + 1000;
        bytes32 dataHash = keccak256(abi.encodePacked(address(nameSpace), alice, name, deadline));
        bytes memory signature = _createEthSign(dataHash);
        nameSpace.register{value: fee}(name, deadline, signature);
        assertEq(address(nameSpace).balance, fee);
        vm.stopPrank();

        vm.expectRevert(bytes4(keccak256("WithdrawTooMuch()")));
        nameSpace.withdraw(fee + 0.01 ether);
    }

}