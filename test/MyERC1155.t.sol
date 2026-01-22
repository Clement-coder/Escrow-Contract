// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyERC1155.sol";

contract MyERC1155Test is Test {
    MyERC1155 public myERC1155;
    address public deployer = makeAddr("deployer");
    address public user1 = makeAddr("user1");

    uint256 public constant ARTWORK_ID = 0;
    uint256 public constant MEMBERSHIP_ID = 1;

    function setUp() public {
        vm.startPrank(deployer);
        myERC1155 = new MyERC1155();
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(myERC1155.balanceOf(deployer, ARTWORK_ID), 1000);
        assertEq(myERC1155.balanceOf(deployer, MEMBERSHIP_ID), 1);
        assertEq(myERC1155.uri(ARTWORK_ID), "https://game.example/api/item/{id}.json");
    }

    function testMint() public {
        uint256 amount = 100;
        vm.prank(deployer);
        myERC1155.mint(user1, ARTWORK_ID, amount, "");

        assertEq(myERC1155.balanceOf(user1, ARTWORK_ID), amount);
    }

    function testBurn() public {
        uint256 burnAmount = 50;
        uint256 initialBalance = myERC1155.balanceOf(deployer, ARTWORK_ID);

        vm.prank(deployer);
        myERC1155.burn(deployer, ARTWORK_ID, burnAmount);

        assertEq(myERC1155.balanceOf(deployer, ARTWORK_ID), initialBalance - burnAmount);
    }

    function testBurnInsufficientBalance() public {
        uint256 burnAmount = myERC1155.balanceOf(deployer, ARTWORK_ID) + 1;

        vm.prank(deployer);
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        myERC1155.burn(deployer, ARTWORK_ID, burnAmount);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        myERC1155.mint(user1, ARTWORK_ID, 100, "");
    }
}
