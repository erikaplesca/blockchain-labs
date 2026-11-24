// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CountingReceiver} from "../src/EtherReceiver.sol";
import {VulnerableAuction, SecureAuction, Attacker} from "../src/Auction.sol";
import {TransferAuction, CarelessBank, FixedBank, RevertingClient} from "../src/Ex2.sol";

contract Ex2Test is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address mallory = makeAddr("mallory");

    function setUp() public {
        vm.deal(address(this), 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(mallory, 10 ether);
    }

    // ---------------- 2.1 ----------------

    function test_2_1_AttackFailsOnTransferAuction() public {
        TransferAuction auction = new TransferAuction();
        vm.prank(alice);
        auction.placeBid{value: 5 ether}();
        vm.prank(bob);
        auction.placeBid{value: 2 ether}();
        vm.prank(mallory);
        Attacker attacker = new Attacker(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        vm.prank(mallory);
        vm.expectRevert(bytes("Attack failed"));
        attacker.attack();

        assertEq(address(auction).balance, 8 ether);   // nu a furat nimic
    }

    // ---------------- 2.2 ----------------

    function test_2_2_ContractBidderStuckInTransferAuction() public {
        TransferAuction auction = new TransferAuction();
        CountingReceiver c = new CountingReceiver();
        c.bid{value: 1 ether}(address(auction));
        vm.prank(alice);
        auction.placeBid{value: 5 ether}();
        auction.endAuction();

        // receive-ul lui CountingReceiver scrie in storage -> nu ajung 2300 gas
        vm.expectRevert(bytes("withdraw failed"));
        c.withdrawFrom(address(auction));

        // si a doua oara, si a zecea oara... banii lui raman blocati pentru totdeauna
        vm.expectRevert(bytes("withdraw failed"));
        c.withdrawFrom(address(auction));

        assertEq(auction.bids(address(c)), 1 ether);
        assertEq(address(auction).balance, 6 ether);
    }

    function test_2_2_ContractBidderOkInSecureAuction() public {
        SecureAuction auction = new SecureAuction();
        CountingReceiver c = new CountingReceiver();
        c.bid{value: 1 ether}(address(auction));
        vm.prank(alice);
        auction.placeBid{value: 5 ether}();
        auction.endAuction();

        c.withdrawFrom(address(auction));                // call da tot gas-ul -> merge
        assertEq(c.totalReceived(), 1 ether);
        assertEq(address(c).balance, 1 ether);
    }

    // ---------------- 2.3 ----------------

    function test_2_3_CarelessBankLosesTrackOfEther() public {
        CarelessBank bank = new CarelessBank();
        RevertingClient client = new RevertingClient();
        client.deposit{value: 1 ether}(address(bank));

        client.withdraw(address(bank), 1 ether);         // nu da revert!

        console.log("sold in mapping :", bank.balances(address(client)));
        console.log("ether in banca  :", address(bank).balance);
        console.log("ether la client :", address(client).balance);
        assertEq(bank.balances(address(client)), 0);     // soldul a fost scazut
        assertEq(address(bank).balance, 1 ether);        // dar ether-ul a ramas in banca
        assertEq(address(client).balance, 0);            // si clientul nu l-a primit
    }

    function test_2_3_FixedBankReverts() public {
        FixedBank bank = new FixedBank();
        RevertingClient client = new RevertingClient();
        client.deposit{value: 1 ether}(address(bank));

        vm.expectRevert(bytes("Transfer failed"));
        client.withdraw(address(bank), 1 ether);

        assertEq(bank.balances(address(client)), 1 ether);   // soldul a ramas corect
        assertEq(address(bank).balance, 1 ether);
    }

    // ---------------- 2.4 ----------------

    function test_2_4_CallToAddressWithoutCode() public {
        address nobody = makeAddr("nobody");
        assertEq(nobody.code.length, 0);

        (bool ok,) = nobody.call{value: 1 ether}("");
        console.log("call cu 1 ether catre o adresa fara cod:", ok);
        assertTrue(ok);
        assertEq(nobody.balance, 1 ether);

        // si cu calldata de functie: tot true, desi nu exista nicio functie placeBid acolo
        (ok,) = nobody.call(abi.encodeWithSignature("placeBid()"));
        console.log("call placeBid() catre o adresa fara cod:", ok);
        assertTrue(ok);

        // un apel normal (high-level) verifica intai ca exista cod la adresa (extcodesize) si da revert
        // revert-ul se produce chiar in contractul care face apelul, de aceea il pun intr-o functie externa
        vm.expectRevert();
        this.highLevelPlaceBid(nobody);
    }

    function highLevelPlaceBid(address target) external {
        VulnerableAuction(target).placeBid{value: 1 ether}();
    }
}
