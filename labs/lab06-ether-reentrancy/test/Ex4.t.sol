// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {PushAuction, PullAuction, MaliciousRejecter} from "../src/Ex4.sol";

contract Ex4Test is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address seller = makeAddr("seller");

    function setUp() public {
        vm.deal(address(this), 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    // ---------------- 4.1 ----------------

    function test_4_1_PushAuctionBlockedByRejecter() public {
        PushAuction auction = new PushAuction();
        MaliciousRejecter rejecter = new MaliciousRejecter(address(auction));

        vm.prank(alice);
        auction.placeBid{value: 1 ether}();
        rejecter.bid{value: 2 ether}();                  // Alice primeste inapoi 1 ether, ok
        assertEq(alice.balance, 10 ether);

        vm.prank(bob);
        vm.expectRevert(bytes("Refund failed"));         // refund-ul catre rejecter da revert
        auction.placeBid{value: 3 ether}();

        // nimeni nu mai poate licita mai mult: rejecter castiga cu 2 ether
        assertEq(auction.highestBidder(), address(rejecter));
        assertEq(auction.highestBid(), 2 ether);
        assertEq(bob.balance, 10 ether);                 // oferta lui Bob a fost anulata complet
    }

    // ---------------- 4.2 ----------------

    function test_4_2_PullAuctionBobCanOutbid() public {
        vm.prank(seller);
        PullAuction auction = new PullAuction();
        MaliciousRejecter rejecter = new MaliciousRejecter(address(auction));

        vm.prank(alice);
        auction.placeBid{value: 1 ether}();
        rejecter.bid{value: 2 ether}();
        vm.prank(bob);
        auction.placeBid{value: 3 ether}();              // merge!

        assertEq(auction.highestBidder(), bob);
        assertEq(auction.pendingReturns(alice), 1 ether);
        assertEq(auction.pendingReturns(address(rejecter)), 2 ether);

        vm.prank(alice);
        auction.withdraw();                              // Alice isi ia banii
        assertEq(alice.balance, 10 ether);

        vm.expectRevert(bytes("withdraw failed"));       // doar rejecter-ul nu isi poate lua banii
        rejecter.withdrawFrom();
        assertEq(auction.pendingReturns(address(rejecter)), 2 ether);
    }

    // ---------------- 4.3 ----------------

    function sumPending(PullAuction auction, address[] memory who) internal view returns (uint256 s) {
        for (uint256 i = 0; i < who.length; i++) s += auction.pendingReturns(who[i]);
    }

    function test_4_3_BalanceEqualsPendingAfterClaim() public {
        vm.prank(seller);
        PullAuction auction = new PullAuction();
        MaliciousRejecter rejecter = new MaliciousRejecter(address(auction));
        address[] memory bidders = new address[](3);
        bidders[0] = alice; bidders[1] = address(rejecter); bidders[2] = bob;

        vm.prank(alice);
        auction.placeBid{value: 1 ether}();
        rejecter.bid{value: 2 ether}();
        vm.prank(bob);
        auction.placeBid{value: 3 ether}();

        vm.prank(alice);
        auction.withdraw();

        vm.prank(seller);
        auction.endAuction();

        // inainte de claim: sold = pendingReturns + oferta castigatoare
        assertEq(address(auction).balance, sumPending(auction, bidders) + auction.highestBid());

        vm.prank(seller);
        auction.claim();
        assertEq(seller.balance, 3 ether);

        // dupa claim: sold = doar pendingReturns nerestituite (cei 2 ether ai rejecter-ului)
        console.log("sold contract       :", address(auction).balance);
        console.log("suma pendingReturns :", sumPending(auction, bidders));
        assertEq(address(auction).balance, sumPending(auction, bidders));

        // nu se poate plati de doua ori
        vm.prank(seller);
        vm.expectRevert(bytes("Already claimed"));
        auction.claim();

        vm.prank(bob);                                   // castigatorul nu are nimic in pendingReturns
        vm.expectRevert(bytes("Nothing to withdraw"));
        auction.withdraw();

        vm.prank(alice);                                 // dupa final nu se mai poate licita
        vm.expectRevert(bytes("Auction ended"));
        auction.placeBid{value: 5 ether}();
    }

    // ---------------- 4.4 ----------------
    // 5 ofertanti, fiecare cu o oferta mai mare decat precedentul
    // (Foundry raporteaza gas-ul tranzactiei, cu tot cu cei 21000 de baza)

    function bidders5() internal returns (address[] memory b) {
        b = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            b[i] = makeAddr(string.concat("bidder", vm.toString(i + 1)));
            vm.deal(b[i], 10 ether);
        }
    }

    function test_4_4_Push5Bidders() public {
        PushAuction auction = new PushAuction();
        address[] memory b = bidders5();
        uint256 total;
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(b[i]);
            auction.placeBid{value: (i + 1) * 1 ether}();
            total += vm.lastFrameGas().gasTotalUsed;
        }
        console.log("Push: 5 tranzactii placeBid          :", total);
    }

    function test_4_4_Pull5Bidders() public {
        vm.prank(seller);
        PullAuction auction = new PullAuction();
        address[] memory b = bidders5();
        uint256 bidGas;
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(b[i]);
            auction.placeBid{value: (i + 1) * 1 ether}();
            bidGas += vm.lastFrameGas().gasTotalUsed;
        }
        uint256 withdrawGas;
        for (uint256 i = 0; i < 4; i++) {                // castigatorul (b[4]) nu are ce retrage
            vm.prank(b[i]);
            auction.withdraw();
            withdrawGas += vm.lastFrameGas().gasTotalUsed;
        }
        console.log("Pull: 5 tranzactii placeBid          :", bidGas);
        console.log("Pull: 4 tranzactii withdraw          :", withdrawGas);
        console.log("Pull: total (9 tranzactii)           :", bidGas + withdrawGas);
    }
}
