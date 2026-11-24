// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Ex 4.1 - licitatie "push": la o oferta noua, il plateste imediat pe cel depasit
contract PushAuction {
    address public highestBidder;
    uint256 public highestBid;

    function placeBid() external payable {
        require(msg.value > highestBid, "Bid too low");

        address previousBidder = highestBidder;
        uint256 previousBid = highestBid;
        highestBidder = msg.sender;
        highestBid = msg.value;

        if (previousBidder != address(0)) {
            (bool success,) = previousBidder.call{value: previousBid}("");
            require(success, "Refund failed");     // daca cel vechi refuza banii, nimeni nu mai poate licita
        }
    }
}

// Ex 4.2 / 4.3 - licitatie "pull": doar noteaza cat datoreaza, fiecare isi retrage singur banii
contract PullAuction {
    address public immutable seller;
    address public highestBidder;
    uint256 public highestBid;
    bool public ended;
    bool public claimed;

    mapping(address => uint256) public pendingReturns;

    constructor() {
        seller = msg.sender;
    }

    function placeBid() external payable {
        require(!ended, "Auction ended");
        require(msg.value > highestBid, "Bid too low");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;   // nu trimit nimic, doar notez
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    // checks - effects - interactions
    function withdraw() external {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingReturns[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // Ex 4.3 - doar marcheaza licitatia ca terminata, nu plateste pe nimeni
    function endAuction() external {
        require(msg.sender == seller, "Only seller");
        require(!ended, "Already ended");
        ended = true;
    }

    // Ex 4.3 - vanzatorul ia cea mai mare oferta, o singura data
    function claim() external {
        require(msg.sender == seller, "Only seller");
        require(ended, "Auction not ended");
        require(!claimed, "Already claimed");
        claimed = true;
        (bool success,) = seller.call{value: highestBid}("");
        require(success, "Claim failed");
    }
}

// Ex 4.1 - liciteaza, dar refuza orice ether trimis inapoi
contract MaliciousRejecter {
    address auction;

    constructor(address auctionAddress) {
        auction = auctionAddress;
    }

    function bid() external payable {
        (bool ok,) = auction.call{value: msg.value}(abi.encodeWithSignature("placeBid()"));
        require(ok, "bid failed");
    }

    function withdrawFrom() external {
        (bool ok,) = auction.call(abi.encodeWithSignature("withdraw()"));
        require(ok, "withdraw failed");
    }

    receive() external payable {
        revert("No refunds, thanks");
    }
}
