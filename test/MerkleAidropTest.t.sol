// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagleToken} from "../src/BagleToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    MerkleAirdrop merkleAirdrop;
    BagleToken bagleToken;
    bytes32 merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivatekey;
    address gasPayer;
    uint256 constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, bagleToken) = deployer.run();
        } else {
            bagleToken = new BagleToken();
            merkleAirdrop = new MerkleAirdrop(merkleRoot, bagleToken);
            bagleToken.mint(bagleToken.owner(), AMOUNT_TO_SEND);
            bagleToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND);
        }
        (user, userPrivatekey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function test_UserCanClaim() public {
        uint256 startingBalance = bagleToken.balanceOf(user);
        console.log("starting balance", startingBalance);

        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivatekey, digest);

        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, (PROOF), v, r, s);

        uint256 endingBalance = bagleToken.balanceOf(user);
        console.log("ending balance", endingBalance);

        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
