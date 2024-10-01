// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagleToken} from "../src/BagleToken.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    MerkleAirdrop merkleAirdrop;
    BagleToken bagleToken;
    bytes32 merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 AMOUNT_TO_SEND = 4 * 25 * 1e18;

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagleToken) {
        vm.startBroadcast();
        bagleToken = new BagleToken();
        merkleAirdrop = new MerkleAirdrop(merkleRoot, IERC20(address(bagleToken)));
        bagleToken.mint(bagleToken.owner(), AMOUNT_TO_SEND);
        bagleToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        vm.stopBroadcast();
        return (merkleAirdrop, bagleToken);
    }

    function run() external returns (MerkleAirdrop, BagleToken) {
        return deployMerkleAirdrop();
    }
}
