// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, stdJson} from "forge-std/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";

contract MerkleTest is Test {
    Airdrop public airdrop;
    using stdJson for string;
    struct Result {
        bytes32 leaf;
        bytes32[] proof;
    }
    bytes32 root =
        0xc87618c6c49eb4b0825fe2b7323eb2d0a34647d57571acbc0eed60825db81123;

    address user1 = 0x001Daa61Eaa241A8D89607194FC3b1184dcB9B4C;
    uint user1Amt = 45000000000000;

    Result public data;

    event AddressClaim(address account, uint256 amount);

    function setUp() public {
        airdrop = new Airdrop(root);
        string memory _root = vm.projectRoot();
        string memory path = string.concat(_root, "/merkle_tree.json");
        string memory json = vm.readFile(path);

        bytes memory res = json.parseRaw(
            string.concat(".", vm.toString(user1))
        );

        data = abi.decode(res, (Result));
    }

    function _claim() internal returns (bool success) {
        success = airdrop.claim(data.proof, user1, user1Amt);
    }

    function testClaimTwice() public {
        _claim();
        vm.expectRevert("You have already claimed!");
        _claim();
    }

    function testClaim() public {
        bool success = _claim();

        assertEq(airdrop.balanceOf(user1), user1Amt);

        assertTrue(success);
    }

    function testFailInvalidAddress() public {
        address user3 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        airdrop.claim(data.proof, user3, user1Amt);
        // assertFalse(success);
        // assertEq(airdrop.balanceOf(user3), user1Amt);
    }

    function testFailInvalidAmount() public {
        uint256 user3Amt = 400 ether;
        airdrop.claim(data.proof, user1, user3Amt);
        // assertFalse(success);
        // assertEq(airdrop.balanceOf(user1), user1Amt);
    }

    function testFailInvalidProof() public {
        bytes32[] memory eProof;
        airdrop.claim(eProof, user1, user1Amt);
        // assertFalse(success);
        // assertEq(airdrop.balanceOf(user1), user1Amt);
    }

    function testClaimEvents() public {
        vm.expectEmit(true, true, false, true);
        emit AddressClaim(user1, user1Amt);
        _claim();
    }
}
