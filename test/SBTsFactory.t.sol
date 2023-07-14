// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "forge-std/Test.sol";
import "../contracts/SBTsFactory.sol";

interface IPromptSBT is IExpirePromptSBT, IERC721Enumerable {}

contract SBTsFactoryTest is Test {
    SBTsFactory factory;

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    function _createSign(bytes32 dataHash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, dataHash);
        return abi.encodePacked(r, s, v);
    }

    function setUp() public {
        factory = new SBTsFactory();
        factory.initialize(admin);

        // init add new promptType SBT contract
        factory.createNewSBT("SBT-Type-A", "TypeA", "http://type-a.com/", admin);
        factory.createNewSBT("SBT-Type-B", "TypeB", "http://type-b.com/", admin);
        factory.createNewSBT("SBT-Type-C", "TypeC", "http://type-c.com/", admin);
    }

    function test_Default() public {
        vm.startPrank(alice);
        assertEq(factory.getSigNonce(), 0);
        vm.stopPrank();

        factory.addSBTContract(vm.addr(4));
        assertEq(factory.sbtContracts(3), vm.addr(4));
        assertEq(factory.isValidSBTContract(vm.addr(4)), true);

        factory.removeSBTContract(vm.addr(4));
        assertEq(factory.isValidSBTContract(vm.addr(4)), false);

        assertEq(factory.trustSigner(), admin);
        factory.setTrustSigner(alice);
        assertEq(factory.trustSigner(), alice);
    }

    function test_BatchMint() public {
        address typeA = factory.sbtContracts(0);
        address typeB = factory.sbtContracts(1);
        address typeC = factory.sbtContracts(2);

        string[] memory tokenURIs = new string[](4);
        tokenURIs[0] = "https://cell.xzy/1";
        tokenURIs[1] = "https://cell.xzy/2";
        tokenURIs[2] = "https://cell.xzy/3";
        tokenURIs[3] = "https://cell.xzy/4";

        address[] memory typeContracts = new address[](4);
        typeContracts[0] = typeA;
        typeContracts[1] = typeA;
        typeContracts[2] = typeB;
        typeContracts[3] = typeC;

        uint256 deadline = block.timestamp + 1000;
        vm.startPrank(alice);
        uint256 sigNonces = factory.getSigNonce() + 1;
        bytes32 dataHash = keccak256(abi.encodePacked(address(factory), alice, sigNonces, deadline));
        vm.stopPrank();

        bytes memory signature = _createSign(dataHash);
        address addr = ECDSA.recover(dataHash, signature);
        assertEq(addr, admin);

        vm.prank(alice);
        factory.batchMint(typeContracts, tokenURIs, deadline, signature);

        assertEq(IPromptSBT(typeA).balanceOf(alice), 2);
        assertEq(IPromptSBT(typeB).balanceOf(alice), 1);
        assertEq(IPromptSBT(typeC).balanceOf(alice), 1);

        assertEq(IPromptSBT(typeA).tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(IPromptSBT(typeA).tokenOfOwnerByIndex(alice, 1), 2);
    }

    function test_BatchMint_WithExpireTime() public {
        address typeA = factory.sbtContracts(0);
        address typeB = factory.sbtContracts(1);
        address typeC = factory.sbtContracts(2);

        string[] memory tokenURIs = new string[](3);
        tokenURIs[0] = "https://cell.xzy/1";
        tokenURIs[1] = "https://cell.xzy/2";
        tokenURIs[2] = "https://cell.xzy/3";

        address[] memory typeContracts = new address[](3);
        typeContracts[0] = typeA;
        typeContracts[1] = typeB;
        typeContracts[2] = typeC;

        uint256[] memory expireTimes = new uint256[](3);
        expireTimes[0] = block.timestamp + 100;
        expireTimes[1] = block.timestamp + 200;
        expireTimes[2] = block.timestamp + 300;

        uint256 deadline = block.timestamp + 1000;
        vm.startPrank(alice);
        uint256 sigNonces = factory.getSigNonce() + 1;
        bytes32 dataHash = keccak256(abi.encodePacked(address(factory), alice, sigNonces, deadline));
        vm.stopPrank();

        bytes memory signature = _createSign(dataHash);
        address addr = ECDSA.recover(dataHash, signature);
        assertEq(addr, admin);

        vm.prank(alice);
        factory.batchMint(typeContracts, tokenURIs, expireTimes, deadline, signature);

        assertEq(IPromptSBT(typeA).expireOf(1), expireTimes[0]);

        assertEq(IPromptSBT(typeA).balanceOf(alice), 1);
        assertEq(IPromptSBT(typeB).balanceOf(alice), 1);
        assertEq(IPromptSBT(typeC).balanceOf(alice), 1);

        assertEq(IPromptSBT(typeA).tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(IPromptSBT(typeB).tokenOfOwnerByIndex(alice, 0), 1);
        assertEq(IPromptSBT(typeC).tokenOfOwnerByIndex(alice, 0), 1);
    }

    function test_BatchBurn() public {
        test_BatchMint_WithExpireTime();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 1;
        tokenIds[2] = 1;

        address[] memory typeContracts = new address[](3);
        typeContracts[0] = factory.sbtContracts(0);
        typeContracts[1] = factory.sbtContracts(1);
        typeContracts[2] = factory.sbtContracts(2);

        vm.prank(alice);
        factory.batchBurn(typeContracts, tokenIds);

        assertEq(IPromptSBT(typeContracts[0]).balanceOf(alice), 0);
        assertEq(IPromptSBT(typeContracts[1]).balanceOf(alice), 0);
        assertEq(IPromptSBT(typeContracts[2]).balanceOf(alice), 0);
    }

}