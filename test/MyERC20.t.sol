// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyERC20.sol";

contract MyERC20RewriteTest is Test {
    MyERC20 public myERC20;
    address public deployer = makeAddr("deployer");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 1 million tokens

    function setUp() public {
        vm.prank(deployer);
        myERC20 = new MyERC20(INITIAL_SUPPLY);
        // No need to deal funds to deployer, they get the initial supply
    }

    function test_InitialSupply_IsCorrect() public {
        assertEq(myERC20.totalSupply(), INITIAL_SUPPLY, "Total supply should match initial supply");
        assertEq(myERC20.balanceOf(deployer), INITIAL_SUPPLY, "Deployer should have the initial supply");
    }

    function test_Mint_IncreasesTotalSupplyAndRecipientBalance() public {
        uint256 mintAmount = 100 * 10 ** 18;
        vm.prank(deployer);
        myERC20.mint(user1, mintAmount);

        assertEq(myERC20.balanceOf(user1), mintAmount, "User1 balance should be the minted amount");
        assertEq(myERC20.totalSupply(), INITIAL_SUPPLY + mintAmount, "Total supply should increase by mint amount");
    }

    function test_Transfer_MovesTokensCorrectly() public {
        uint256 transferAmount = 50 * 10 ** 18;
        vm.prank(deployer);
        myERC20.transfer(user1, transferAmount);

        assertEq(myERC20.balanceOf(deployer), INITIAL_SUPPLY - transferAmount, "Deployer balance should decrease");
        assertEq(myERC20.balanceOf(user1), transferAmount, "User1 balance should increase");
    }

    function test_Transfer_FailsWithInsufficientBalance() public {
        uint256 transferAmount = 100 * 10 ** 18;
        // user1 has 0 balance
        vm.prank(user1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        myERC20.transfer(user2, transferAmount);
    }
    
    function test_ApproveAndTransferFrom_WorksAsExpected() public {
        uint256 approveAmount = 100 * 10 ** 18;
        uint256 transferAmount = 75 * 10 ** 18;

        // Deployer approves user1
        vm.prank(deployer);
        myERC20.approve(user1, approveAmount);
        assertEq(myERC20.allowance(deployer, user1), approveAmount, "Allowance should be set correctly");

        // user1 transfers from deployer to user2
        vm.prank(user1);
        myERC20.transferFrom(deployer, user2, transferAmount);

        assertEq(myERC20.balanceOf(deployer), INITIAL_SUPPLY - transferAmount, "Deployer balance should decrease");
        assertEq(myERC20.balanceOf(user2), transferAmount, "User2 balance should increase");
        assertEq(myERC20.allowance(deployer, user1), approveAmount - transferAmount, "Allowance should be reduced");
    }

    function test_Mint_FailsIfSenderIsNotOwner() public {
        uint256 mintAmount = 100 * 10 ** 18;
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        myERC20.mint(user1, mintAmount);
    }
}
