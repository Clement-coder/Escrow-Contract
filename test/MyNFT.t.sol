// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public myNft;
    address public deployer = makeAddr("deployer");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        vm.startPrank(deployer);
        myNft = new MyNFT();
        vm.stopPrank();
    }

    function testMinting() public {
        string memory uri = "ipfs://testuri";
        vm.startPrank(deployer);
        myNft.safeMint(user1, uri);
        vm.stopPrank();

        assertEq(myNft.ownerOf(0), user1);
        assertEq(myNft.tokenURI(0), uri);
    }

    function testOnlyOwnerCanMint() public {
        vm.startPrank(user1);
        // This should revert because only the owner can mint
        vm.expectRevert("Ownable: caller is not the owner");
        myNft.safeMint(user1, "ipfs://testuri");
        vm.stopPrank();
    }
}
