// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MerkleProof} from "@openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {BagleToken} from "./BagleToken.sol";
import {EIP712} from "@openzeppelin-contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    bytes32 immutable i_merkleRoot;
    IERC20 immutable i_airdropToken;

    mapping(address => bool) s_hasClaimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    bytes32 MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    address[] claimers;

    event Claim(address indexed account, uint256 indexed amount);

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata _merkleProof, uint8 v, bytes32 r, bytes32 s)
        public
    {
        if (s_hasClaimed[account]) revert MerkleAirdrop__AlreadyClaimed();
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) revert MerkleAirdrop__InvalidProof();

        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSignature,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSignature == account;
    }

    function hasClaimed(address user) public view returns (bool) {
        return s_hasClaimed[user];
    }
}
