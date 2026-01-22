// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol"; // Using Ownable for simplicity for initial minting

contract MyERC20 is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Function to mint new tokens - restricted to owner
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
