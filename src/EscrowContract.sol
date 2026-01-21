// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EscrowContract {
    enum State { Created, Funded, Delivered, Completed, Disputed, Refunded }
    
    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        State state;
        bool buyerConfirmed;
        bool sellerConfirmed;
        uint256 createdAt;
        string description;
    }
    
    mapping(uint256 => Escrow) public escrows;
    uint256 public nextEscrowId = 1;
    address public arbiter;
    uint256 public fee = 1; // 1% fee
    
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId);
    event DeliveryConfirmed(uint256 indexed escrowId, address indexed confirmer);
    event EscrowCompleted(uint256 indexed escrowId);
    event EscrowRefunded(uint256 indexed escrowId);
    event DisputeRaised(uint256 indexed escrowId);
    
    modifier onlyParties(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer || msg.sender == escrows[escrowId].seller, "Not authorized");
        _;
    }
    
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }
    
    modifier inState(uint256 escrowId, State expectedState) {
        require(escrows[escrowId].state == expectedState, "Invalid state");
        _;
    }
    
    constructor() {
        arbiter = msg.sender;
    }
    
    function createEscrow(address seller, string memory description) external payable {
        require(msg.value > 0, "Amount must be > 0");
        require(seller != address(0) && seller != msg.sender, "Invalid seller");
        
        escrows[nextEscrowId] = Escrow({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            state: State.Funded,
            buyerConfirmed: false,
            sellerConfirmed: false,
            createdAt: block.timestamp,
            description: description
        });
        
        emit EscrowCreated(nextEscrowId, msg.sender, seller, msg.value);
        emit EscrowFunded(nextEscrowId);
        
        nextEscrowId++;
    }
    
    function confirmDelivery(uint256 escrowId) external 
        onlyParties(escrowId) 
        inState(escrowId, State.Funded) 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (msg.sender == escrow.buyer) {
            escrow.buyerConfirmed = true;
        } else {
            escrow.sellerConfirmed = true;
        }
        
        emit DeliveryConfirmed(escrowId, msg.sender);
        
        // Release funds if both parties confirmed
        if (escrow.buyerConfirmed && escrow.sellerConfirmed) {
            _completeTrade(escrowId);
        }
    }
    
    function _completeTrade(uint256 escrowId) internal {
        Escrow storage escrow = escrows[escrowId];
        escrow.state = State.Completed;
        
        uint256 feeAmount = (escrow.amount * fee) / 100;
        uint256 sellerAmount = escrow.amount - feeAmount;
        
        (bool success1, ) = escrow.seller.call{value: sellerAmount}("");
        (bool success2, ) = arbiter.call{value: feeAmount}("");
        require(success1 && success2, "Transfer failed");
        
        emit EscrowCompleted(escrowId);
    }
    
    function raiseDispute(uint256 escrowId) external 
        onlyParties(escrowId) 
        inState(escrowId, State.Funded) 
    {
        escrows[escrowId].state = State.Disputed;
        emit DisputeRaised(escrowId);
    }
    
    function resolveDispute(uint256 escrowId, bool favorBuyer) external 
        onlyArbiter 
        inState(escrowId, State.Disputed) 
    {
        Escrow storage escrow = escrows[escrowId];
        
        if (favorBuyer) {
            escrow.state = State.Refunded;
            (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
            require(success, "Refund failed");
            emit EscrowRefunded(escrowId);
        } else {
            escrow.state = State.Completed;
            uint256 feeAmount = (escrow.amount * fee) / 100;
            uint256 sellerAmount = escrow.amount - feeAmount;
            
            (bool success1, ) = escrow.seller.call{value: sellerAmount}("");
            (bool success2, ) = arbiter.call{value: feeAmount}("");
            require(success1 && success2, "Transfer failed");
            emit EscrowCompleted(escrowId);
        }
    }
    
    function refundBuyer(uint256 escrowId) external 
        onlyArbiter 
        inState(escrowId, State.Funded) 
    {
        Escrow storage escrow = escrows[escrowId];
        escrow.state = State.Refunded;
        
        (bool success, ) = escrow.buyer.call{value: escrow.amount}("");
        require(success, "Refund failed");
        
        emit EscrowRefunded(escrowId);
    }
    
    function getEscrow(uint256 escrowId) external view returns (Escrow memory) {
        return escrows[escrowId];
    }
    
    function setArbiter(address newArbiter) external onlyArbiter {
        arbiter = newArbiter;
    }
    
    function setFee(uint256 newFee) external onlyArbiter {
        require(newFee <= 5, "Fee too high"); // Max 5%
        fee = newFee;
    }
}
