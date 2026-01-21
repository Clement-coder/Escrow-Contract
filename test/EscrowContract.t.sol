// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {EscrowContract} from "../src/EscrowContract.sol";

contract EscrowContractTest is Test {
    EscrowContract public escrow;
    address public buyer = address(0x123);
    address public seller = address(0x456);
    address public arbiter = address(this);
    
    receive() external payable {}
    
    function setUp() public {
        escrow = new EscrowContract();
        vm.deal(buyer, 10 ether);
        vm.deal(seller, 10 ether);
    }
    
    function testCreateEscrow() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "iPhone purchase");
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(escrowData.buyer, buyer);
        assertEq(escrowData.seller, seller);
        assertEq(escrowData.amount, 1 ether);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Funded));
    }
    
    function testBothPartiesConfirmDelivery() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Laptop purchase");
        
        uint256 arbiterBalanceBefore = address(this).balance;
        uint256 sellerBalanceBefore = seller.balance;
        
        // Buyer confirms delivery
        vm.prank(buyer);
        escrow.confirmDelivery(1);
        
        // Seller confirms delivery
        vm.prank(seller);
        escrow.confirmDelivery(1);
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Completed));
        
        // Check payments (1% fee = 0.01 ether, seller gets 0.99 ether)
        assertEq(address(this).balance, arbiterBalanceBefore + 0.01 ether);
        assertEq(seller.balance, sellerBalanceBefore + 0.99 ether);
    }
    
    function testSinglePartyConfirmation() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Phone purchase");
        
        // Only buyer confirms
        vm.prank(buyer);
        escrow.confirmDelivery(1);
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertTrue(escrowData.buyerConfirmed);
        assertFalse(escrowData.sellerConfirmed);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Funded)); // Still funded
    }
    
    function testRaiseDispute() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Disputed item");
        
        vm.prank(buyer);
        escrow.raiseDispute(1);
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Disputed));
    }
    
    function testResolveDisputeFavorBuyer() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Faulty product");
        
        vm.prank(buyer);
        escrow.raiseDispute(1);
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        escrow.resolveDispute(1, true); // Favor buyer
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Refunded));
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }
    
    function testResolveDisputeFavorSeller() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Valid delivery");
        
        vm.prank(seller);
        escrow.raiseDispute(1);
        
        uint256 sellerBalanceBefore = seller.balance;
        uint256 arbiterBalanceBefore = address(this).balance;
        
        escrow.resolveDispute(1, false); // Favor seller
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Completed));
        assertEq(seller.balance, sellerBalanceBefore + 0.99 ether);
        assertEq(address(this).balance, arbiterBalanceBefore + 0.01 ether);
    }
    
    function testRefundBuyer() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Cancelled order");
        
        uint256 buyerBalanceBefore = buyer.balance;
        
        escrow.refundBuyer(1);
        
        EscrowContract.Escrow memory escrowData = escrow.getEscrow(1);
        assertEq(uint(escrowData.state), uint(EscrowContract.State.Refunded));
        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
    }
    
    function testUnauthorizedAccess() public {
        vm.prank(buyer);
        escrow.createEscrow{value: 1 ether}(seller, "Protected transaction");
        
        address unauthorized = address(0x999);
        vm.prank(unauthorized);
        vm.expectRevert("Not authorized");
        escrow.confirmDelivery(1);
    }
}
