// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";
import "../src/FidelityPoints.sol";

// Ex. 7: câte un test pentru fiecare funcție optimizată, ca forge snapshot --diff să arate efectul fiecărei tehnici
// rulează cu: forge snapshot --match-contract FidelityGasTest --isolate
contract FidelityGasTest is Test {
    Catalog cat;
    FidelityPoints fp;
    address client = makeAddr("client");

    function setUp() public {
        cat = new Catalog();
        fp = new FidelityPoints(10);
        fp.setCatalog(address(cat));
        cat.setFidelityProgram(address(fp));
        cat.addProduct("P001", "Coffee mug", 55, 3);
        fp.addPoints(client, 100);
    }

    // 7.1: addPoints citește admin la fiecare apel (onlyAdmin)
    function test_AddPoints() public {
        fp.addPoints(client, 50);
    }

    // 7.2: spendPoints citește points[msg.sender] de mai multe ori
    function test_SpendPoints() public {
        vm.prank(client);
        fp.spendPoints(10);
    }

    // 7.2: redeem
    function test_Redeem() public {
        vm.prank(client);
        fp.redeem("P001", 1);
    }

    // 7.3: 10 clienți, câte o tranzacție addPoints pentru fiecare
    function test_AddPoints10Clients() public {
        for (uint i = 1; i <= 10; i++) {
            fp.addPoints(address(uint160(i)), 10);
        }
    }

    // 7.4: un apel care face revert
    function test_RevertWhen_NotAdmin() public {
        vm.expectRevert();
        vm.prank(client);
        fp.addPoints(client, 10);
    }

    // 7.2 / 7.4: puncte insuficiente
    function test_RevertWhen_SpendTooMuch() public {
        vm.expectRevert();
        vm.prank(client);
        fp.spendPoints(1000);
    }
}
