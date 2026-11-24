// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Ex 2.1 - copie a lui VulnerableAuction, dar withdraw trimite cu transfer (ordinea gresita a ramas)
contract TransferAuction {
    mapping(address => uint256) public bids;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionEnded;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event Withdrawal(address indexed bidder, uint256 amount);

    function placeBid() external payable {
        require(!auctionEnded, "Auction already ended");
        require(msg.value > 0, "Bid must be greater than 0");

        bids[msg.sender] += msg.value;

        if (bids[msg.sender] > highestBid) {
            highestBidder = msg.sender;
            highestBid = bids[msg.sender];
        }

        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() external {
        require(!auctionEnded, "Auction already ended");
        require(highestBidder != address(0), "No bids placed");
        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function withdraw() external {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender != highestBidder, "Winner cannot withdraw");

        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "No funds to withdraw");

        payable(msg.sender).transfer(refundAmount);   // doar 2300 gas pentru cel care primeste
        bids[msg.sender] = 0;                          // tot dupa interactiune

        emit Withdrawal(msg.sender, refundAmount);
    }

    function bidInfo(address sender) external view returns (uint256) {
        return bids[sender];
    }
}

// Ex 2.3 - banca neglijenta: nu verifica rezultatul lui send
contract CarelessBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;
        payable(msg.sender).send(amount);              // rezultatul e ignorat!
    }
}

// Ex 2.3 - varianta corectata
contract FixedBank {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;                // effects inainte de interactiune
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");                // daca nu a ajuns, se anuleaza tot (si scaderea)
    }
}

// Ex 2.3 - client care nu poate primi ether
contract RevertingClient {
    function deposit(address bank) external payable {
        (bool ok,) = bank.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(ok);
    }

    function withdraw(address bank, uint256 amount) external {
        (bool ok, bytes memory err) = bank.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        if (!ok) {
            assembly { revert(add(err, 32), mload(err)) }   // propag eroarea bancii
        }
    }

    receive() external payable {
        revert("I don't accept ether");
    }
}
