// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";

// Ex. 2.4: două variante de a păstra istoricul cumpărăturilor, ca să le compar costul în gas.

// Varianta 1: istoric în storage (array de structuri)
contract HistoryWithStorage {
    struct Redemption {
        address client;      // slot 0 (20 bytes; bytes32 care urmează nu mai încape lângă)
        bytes32 code;        // slot 1
        uint quantity;       // slot 2
        uint pointsSpent;    // slot 3
    }

    Redemption[] public redemptions;

    function record(address client, bytes32 code, uint quantity, uint pointsSpent) external {
        redemptions.push(Redemption(client, code, quantity, pointsSpent));
    }
}

// Varianta 2: istoric în logs (același event ca în FidelityPoints)
contract HistoryWithEvent {
    event PointsRedeemed(address indexed client, bytes32 indexed code, uint quantity, uint pointsSpent);

    function record(address client, bytes32 code, uint quantity, uint pointsSpent) external {
        emit PointsRedeemed(client, code, quantity, pointsSpent);
    }
}

contract RedemptionHistoryTest is Test {
    HistoryWithStorage withStorage;
    HistoryWithEvent withEvent;
    address client = address(0xC1);

    function setUp() public {
        withStorage = new HistoryWithStorage();
        withEvent = new HistoryWithEvent();
    }

    // de două ori: prima înregistrare schimbă și lungimea array-ului din 0 în 1
    function test_HistoryWithStorage() public {
        withStorage.record(client, "P001", 2, 10);
        withStorage.record(client, "P001", 2, 8);
    }

    function test_HistoryWithEvent() public {
        withEvent.record(client, "P001", 2, 10);
        withEvent.record(client, "P001", 2, 8);
    }
}
