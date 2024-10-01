// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Interaction} from "../script/Interaction.s.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {Vm} from "forge-std/Vm.sol";
import {BagleToken} from "../src/BagleToken.sol";

contract InteractionTest is Test {
    BagleToken bagleToken;
    MerkleAirdrop airdrop;
    Interaction interaction;
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] merkleProof;

    function setUp() public {
        // Deploy the MerkleAirdrop contract for testing
        bagleToken = new BagleToken();
        airdrop = new MerkleAirdrop(0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4, bagleToken);

        // Deploy the Interaction contract for testing
        interaction = new Interaction();

        // Set up Merkle proof
        merkleProof = [proofOne, proofTwo];

        // Label the accounts for easier debugging
        vm.label(CLAIMING_ADDRESS, "Claiming Address");
    }

    function testClaimAirdrop() public {
        // Mock signature - This is for test purposes
        bytes memory signature =
            hex"6c576a2bcd6ec720be706c4a336ac69c3cfee293689bca8205e9ff240e2d69c50084e9509ae54535c86062b05a91e5da8bb22d517e7f72ba879823fd3f56c9361b";

        // Use splitSignature function from Interaction contract
        (uint8 v, bytes32 r, bytes32 s) = interaction.splitSignature(signature);

        // Broadcast and simulate the claim using the MerkleAirdrop contract
        vm.startPrank(CLAIMING_ADDRESS);

        // Mock the merkleProof, v, r, s (These would be validated in the real test)
        airdrop.claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, merkleProof, v, r, s);

        // Assert that the airdrop was claimed
        bool hasClaimed = airdrop.hasClaimed(CLAIMING_ADDRESS);
        assertTrue(hasClaimed, "Airdrop claim should be successful");

        vm.stopPrank();
    }

    function test_removeHexPrefix() public view {
        string memory signature =
            "0xc01d8746e198cb6e957fb824cf3bdc9ff76d60193df45215bded254c3cd28c1177a85da2a41c60f3e1ffe9de3d2e104ea12f13ff3fbdbd9f90673476442a69311c";

        string memory expectedSignature =
            "c01d8746e198cb6e957fb824cf3bdc9ff76d60193df45215bded254c3cd28c1177a85da2a41c60f3e1ffe9de3d2e104ea12f13ff3fbdbd9f90673476442a69311c";
        string memory actualString = interaction.removeHexPrefix(signature);
        console.log(actualString);

        assertEq(keccak256(abi.encode(expectedSignature)), keccak256(abi.encode(actualString)));
    }

    function test_parseSignature() public view {
        string memory signature =
            "0xc01d8746e198cb6e957fb824cf3bdc9ff76d60193df45215bded254c3cd28c1177a85da2a41c60f3e1ffe9de3d2e104ea12f13ff3fbdbd9f90673476442a69311c";

        string memory expectedSignature =
            "c01d8746e198cb6e957fb824cf3bdc9ff76d60193df45215bded254c3cd28c1177a85da2a41c60f3e1ffe9de3d2e104ea12f13ff3fbdbd9f90673476442a69311c";

        string memory actualString = interaction.removeHexPrefix(signature);
        assertEq(keccak256(abi.encode(expectedSignature)), keccak256(abi.encode(actualString)));
        console.logBytes(interaction.parseSignature(actualString));
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = interaction.splitSignature(interaction.parseSignature(actualString));
        console.log(v);
        console.logBytes32(r);
        console.logBytes32(s);
    }
}
