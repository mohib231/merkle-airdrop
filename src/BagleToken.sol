// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";

contract BagleToken is ERC20, Ownable {
    error BagleToken__ValueCannotBeZero();

    constructor() ERC20("Bagle", "BAGLE") Ownable(msg.sender) {}

    function mint(address to, uint256 value) external onlyOwner {
        if (value == 0) {
            revert BagleToken__ValueCannotBeZero();
        }
        _mint(to, value);
    }
}
