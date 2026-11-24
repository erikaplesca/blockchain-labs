// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CountingReceiver} from "../src/EtherReceiver.sol";
import {VulnerableAuction, SecureAuction, Attacker} from "../src/Auction.sol";
import {
    AttackerMax, PrizeAttacker, GuardedAuction, GuardedAuctionStorage, CrossAttacker,
    OriginCheckAuction, DelegatedAttacker
} from "../src/Ex3.sol";

// interfata comuna pentru toate licitatiile (au aceleasi functii)
interface IAuctionFull {
    function placeBid() external payable;
    function endAuction() external;
    function withdraw() external;
    function claimPrize() external;
    function bids(address) external view returns (uint256);
}

contract Ex3Test is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address mallory;
    uint256 malloryKey;

    function setUp() public {
        (mallory, malloryKey) = makeAddrAndKey("mallory");
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(mallory, 10 ether);
    }

    function bids(address auction, uint256 aliceBid, uint256 bobBid) internal {
        vm.prank(alice);
        IAuctionFull(auction).placeBid{value: aliceBid}();
        vm.prank(bob);
        IAuctionFull(auction).placeBid{value: bobBid}();
    }

    // ---------------- 3.1 ----------------

    function test_3_1_Bob25_OriginalAttackerReverts() public {
        VulnerableAuction auction = new VulnerableAuction();
        bids(address(auction), 5 ether, 2.5 ether);
        vm.prank(mallory);
        Attacker attacker = new Attacker(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();
        assertEq(address(auction).balance, 8.5 ether);

        vm.prank(mallory);
        vm.expectRevert(bytes("Attack failed"));
        attacker.attack();

        assertEq(address(auction).balance, 8.5 ether);   // nu a luat nimic, nici macar oferta lui
    }

    function test_3_1_Bob25_FixedAttackerTakesMax() public {
        VulnerableAuction auction = new VulnerableAuction();
        bids(address(auction), 5 ether, 2.5 ether);
        vm.prank(mallory);
        AttackerMax attacker = new AttackerMax(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        vm.prank(mallory);
        attacker.attack();

        console.log("attacker :", address(attacker).balance);
        console.log("licitatie:", address(auction).balance);
        assertEq(address(attacker).balance, 8 ether);
        assertEq(address(auction).balance, 0.5 ether);   // ramane doar ce e mai putin de 1 ether
    }

    // ---------------- 3.2 ----------------

    function test_3_2_PrizeAttackerOnVulnerableAuction() public {
        VulnerableAuction auction = new VulnerableAuction();
        bids(address(auction), 2 ether, 3 ether);
        PrizeAttacker attacker = new PrizeAttacker(address(auction));
        attacker.bid{value: 4 ether}();                  // cea mai mare oferta
        auction.endAuction();
        assertEq(address(auction).balance, 9 ether);

        attacker.attack();

        console.log("attacker :", address(attacker).balance);
        console.log("licitatie:", address(auction).balance);
        assertEq(address(attacker).balance, 8 ether);    // premiul de 2 ori (4 + 4)
        assertEq(address(auction).balance, 1 ether);

        // Bob (3 ether) nu isi mai poate lua banii inapoi
        vm.prank(bob);
        vm.expectRevert(bytes("Withdrawal failed"));
        auction.withdraw();
    }

    function test_3_2_PrizeAttackerOnSecureAuctionGetsOnlyItsPrize() public {
        SecureAuction auction = new SecureAuction();
        bids(address(auction), 2 ether, 3 ether);
        PrizeAttacker attacker = new PrizeAttacker(address(auction));
        attacker.bid{value: 4 ether}();
        auction.endAuction();

        attacker.attack();

        // highestBid e pus pe 0 INAINTE de call, deci in receive attacker-ul vede 0 si nu mai reintra
        // (daca ar reintra, ar primi "Already claimed")
        console.log("attacker :", address(attacker).balance);
        console.log("licitatie:", address(auction).balance);
        assertEq(address(attacker).balance, 4 ether);    // doar premiul lui, o singura data
        assertEq(address(auction).balance, 5 ether);     // banii lui Alice si Bob sunt in siguranta

        vm.prank(bob);
        auction.withdraw();
        assertEq(bob.balance, 10 ether);
    }

    // ---------------- 3.3 ----------------

    function test_3_3_GuardStopsWithdrawAttack() public {
        GuardedAuction auction = new GuardedAuction();
        bids(address(auction), 5 ether, 2 ether);
        vm.prank(mallory);
        Attacker attacker = new Attacker(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        vm.prank(mallory);
        vm.expectRevert(bytes("Attack failed"));
        attacker.attack();
        assertEq(address(auction).balance, 8 ether);
    }

    function test_3_3_GuardStopsPrizeAttack() public {
        GuardedAuction auction = new GuardedAuction();
        bids(address(auction), 2 ether, 3 ether);
        PrizeAttacker attacker = new PrizeAttacker(address(auction));
        attacker.bid{value: 4 ether}();
        auction.endAuction();

        vm.expectRevert(bytes("Attack failed"));
        attacker.attack();
        assertEq(address(auction).balance, 9 ether);
    }

    // din withdraw nu poate intra nici in claimPrize: acelasi lock pentru ambele functii
    function test_3_3_CrossFunctionReentryBlocked() public {
        GuardedAuction auction = new GuardedAuction();
        bids(address(auction), 5 ether, 2 ether);
        CrossAttacker attacker = new CrossAttacker(address(auction));
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        attacker.attack();                               // withdraw-ul lui legitim merge

        assertEq(attacker.lastError(), abi.encodeWithSelector(GuardedAuction.ReentrantCall.selector));
        assertEq(address(attacker).balance, 1 ether);
    }

    // pentru gas report: un withdraw cinstit in fiecare varianta
    function test_3_3_HonestWithdrawTransient() public {
        GuardedAuction auction = new GuardedAuction();
        bids(address(auction), 5 ether, 2 ether);
        auction.endAuction();
        vm.prank(bob);
        auction.withdraw();
        assertEq(bob.balance, 10 ether);
    }

    function test_3_3_HonestWithdrawStorage() public {
        GuardedAuctionStorage auction = new GuardedAuctionStorage();
        bids(address(auction), 5 ether, 2 ether);
        auction.endAuction();
        vm.prank(bob);
        auction.withdraw();
        assertEq(bob.balance, 10 ether);
    }

    // ---------------- 3.4 ----------------

    function test_3_4_OriginCheckBlocksAttackerContract() public {
        OriginCheckAuction auction = new OriginCheckAuction();
        bids(address(auction), 5 ether, 2 ether);
        vm.prank(mallory);
        Attacker attacker = new Attacker(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        vm.prank(mallory, mallory);                      // msg.sender si tx.origin = mallory
        vm.expectRevert(bytes("Attack failed"));         // in withdraw: msg.sender = Attacker != tx.origin
        attacker.attack();
    }

    // dar si un utilizator cinstit care foloseste un contract (ex. un smart wallet / multisig) e blocat
    function test_3_4_OriginCheckBlocksHonestContractWallet() public {
        OriginCheckAuction auction = new OriginCheckAuction();
        CountingReceiver wallet = new CountingReceiver();    // un "wallet" contract care primeste ether normal
        wallet.bid{value: 1 ether}(address(auction));
        bids(address(auction), 5 ether, 2 ether);
        auction.endAuction();

        vm.prank(alice, alice);
        vm.expectRevert(bytes("withdraw failed"));       // "Only EOAs" -> banii lui raman blocati
        wallet.withdrawFrom(address(auction));
        assertEq(auction.bids(address(wallet)), 1 ether);
    }

    // si nici macar nu opreste atacul: cu EIP-7702, un EOA poate avea cod
    function test_3_4_EIP7702BypassesOriginCheck() public {
        OriginCheckAuction auction = new OriginCheckAuction();
        bids(address(auction), 5 ether, 2 ether);
        vm.prank(mallory, mallory);
        auction.placeBid{value: 1 ether}();              // Mallory liciteaza direct din EOA
        auction.endAuction();

        DelegatedAttacker impl = new DelegatedAttacker(address(auction));
        vm.signAndAttachDelegation(address(impl), malloryKey);   // EOA-ul lui Mallory primeste codul lui impl
        assertGt(mallory.code.length, 0);

        uint256 before = mallory.balance;
        vm.prank(mallory, mallory);
        DelegatedAttacker(payable(mallory)).attack();    // Mallory isi apeleaza propriul cont

        console.log("Mallory a castigat:", mallory.balance - before);
        console.log("licitatie         :", address(auction).balance);
        assertEq(address(auction).balance, 0);
        assertEq(mallory.balance - before, 8 ether);
    }
}
