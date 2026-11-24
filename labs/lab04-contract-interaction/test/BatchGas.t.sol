// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/FidelityPoints.sol";

// Ex. 7.3: 10 clienți - 10 tranzacții addPoints vs. o tranzacție addPointsBatch (calldata / memory)
// rulează cu: forge test --match-contract BatchGasTest --isolate -vv
// Foundry 1.9 raportează gas-ul întregii tranzacții (include deja cei 21.000), verificat pe anvil cu receipt-ul
contract BatchGasTest is Test {
    FidelityPoints fp;

    function setUp() public {
        fp = new FidelityPoints(10);
    }

    function tenClients() internal pure returns (address[] memory clients, uint[] memory amounts) {
        clients = new address[](10);
        amounts = new uint[](10);
        for (uint i = 0; i < 10; i++) {
            clients[i] = address(uint160(i + 1));
            amounts[i] = 10;
        }
    }

    function test_1_TenCallsAddPoints() public {
        uint total;
        for (uint i = 1; i <= 10; i++) {
            fp.addPoints(address(uint160(i)), 10);
            total += vm.lastFrameGas().gasTotalUsed;
        }
        console.log("10 tranzactii addPoints      :", total);
    }

    function test_2_BatchCalldata() public {
        (address[] memory clients, uint[] memory amounts) = tenClients();
        fp.addPointsBatch(clients, amounts);
        uint g = vm.lastFrameGas().gasTotalUsed;
        console.log("1 tranzactie batch (calldata):", g);
        assertEq(fp.getTotalPoints(), 100);
    }

    function test_3_BatchMemory() public {
        (address[] memory clients, uint[] memory amounts) = tenClients();
        fp.addPointsBatchMemory(clients, amounts);
        uint g = vm.lastFrameGas().gasTotalUsed;
        console.log("1 tranzactie batch (memory)  :", g);
        assertEq(fp.getTotalPoints(), 100);
    }

    function test_RevertWhen_LengthMismatch() public {
        address[] memory clients = new address[](2);
        uint[] memory amounts = new uint[](1);
        vm.expectRevert(FidelityPoints.LengthMismatch.selector);
        fp.addPointsBatch(clients, amounts);
    }
}
