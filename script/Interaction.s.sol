// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagleToken} from "../src/BagleToken.sol";
import {VRFConsumerBase} from "@chainlink-brownie-contracts/src/v0.8/VRFConsumerBase.sol";

contract Interaction is Script {
    error Interaction__InvalidSignatureLength(string, bytes);

    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] merkleProof = [proofOne, proofTwo];
    bytes SIGNATURE =
        hex"83ee1086ddf7a8a163883f30df93216229b8fcd399ba1643c77bdffe03c4783324a7ee2976a870b0757e805781e4040d24ced33a3be69ded0b4ac9517889c9bd1c";

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, merkleProof, v, r, s);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedContract = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedContract);
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            // First 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // Second 32 bytes
            s := mload(add(sig, 64))
            // Final byte (v is only 1 byte)
            v := byte(0, mload(add(sig, 96)))
        }

        // Adjust v value (27 or 28)
        if (v < 27) {
            v += 27;
        }
    }
}

// contract Signatures is VRFConsumerBase, Script {
//     bytes32 internal keyHash;
//     uint256 internal fee;
//     uint256 public randomResult;
//     address user;
//     address privateKey;
//     MerkleAirdrop merkleAirdrop;
//     BagleToken bagleToken;
//     bytes32 merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
//     uint256 AMOUNT_TO_CLAIM = 25 * 1e18;

//     function run() public returns (uint8, bytes32, bytes32) {
//         vm.startBroadcast();
//         bagleToken = new BagleToken();
//         merkleAirdrop = new MerkleAirdrop(merkleRoot, bagleToken);
//         vm.stopBroadcast();
//         (uint8 v, bytes32 r, bytes32 s) = signatures();
//         return (v, r, s);
//     }

//     constructor()
//         VRFConsumerBase(
//             0x514910771AF9Ca656af840dff83E8264EcF986CA, // VRF Coordinator
//             0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token
//         )
//     {
//         keyHash = 0xAA77729D3466CA35AE8D28D49064638B7C1BD7A4191E97C698B4A5F99B59BB94;
//         fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
//     }

//     function getRandomNumber() public returns (bytes32 requestId) {
//         if (LINK.balanceOf(address(this)) < fee) {
//             revert Signatures__NotEnoughFee();
//         }
//         return requestRandomness(keyHash, fee);
//     }

//     function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
//         randomResult = randomness;
//     }

//     function signatures() public returns (uint8, bytes32, bytes32) {
//         (user, privateKey) = vm.makeAddrAndKey(string(getRandomNumber()));
//         bytes32 digest = merkleAirdrop.getMessageHash(user, Interaction.CLAIMING_AMOUNT());
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
//         return (v, r, s);
//     }
// }
