// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Receiver, OnlyFallback, NoReceive} from "../src/EtherReceiver.sol";
import {VulnerableAuction} from "../src/Auction.sol";
import {ReceiverNoReceive, ReceiverNonPayableFallback, Echo, ForceSend, AttackerWithReceive} from "../src/Ex1.sol";

contract Ex1Test is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address mallory = makeAddr("mallory");

    bytes32 constant VIA_RECEIVE = keccak256("ViaReceive(address,uint256)");
    bytes32 constant VIA_FALLBACK = keccak256("ViaFallback(address,uint256,bytes)");

    function setUp() public {
        vm.deal(address(this), 100 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(mallory, 10 ether);
    }

    // ---------------- 1.1 ----------------

    // trimite un apel si spune ce functie s-a executat, dupa event-ul emis
    // (OnlyFallback nu emite event-uri, la el ma uit la contorul fallbackCalls)
    function which(address target, bytes memory data, uint256 value) internal returns (string memory) {
        uint256 callsBefore = target.code.length > 0 && isOnlyFallback[target] ? OnlyFallback(payable(target)).fallbackCalls() : 0;
        vm.recordLogs();
        (bool ok,) = target.call{value: value}(data);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        if (!ok) return "revert";
        if (isOnlyFallback[target]) {
            return OnlyFallback(payable(target)).fallbackCalls() == callsBefore + 1 ? "fallback" : "?";
        }
        if (logs.length == 1 && logs[0].topics[0] == VIA_RECEIVE) return "receive";
        if (logs.length == 1 && logs[0].topics[0] == VIA_FALLBACK) return "fallback";
        return "?";
    }

    mapping(address => bool) isOnlyFallback;

    function row(string memory name, address target) internal returns (string[4] memory r) {
        bytes memory unknown = hex"12345678";
        r[0] = which(target, "", 0);
        r[1] = which(target, "", 1 ether);
        r[2] = which(target, unknown, 0);
        r[3] = which(target, unknown, 1 ether);
        console.log(string.concat(name, " | ", r[0], " | ", r[1], " | ", r[2], " | ", r[3]));
    }

    function test_1_1_Table() public {
        Receiver r = new Receiver();
        OnlyFallback f = new OnlyFallback();
        isOnlyFallback[address(f)] = true;
        NoReceive n = new NoReceive();
        ReceiverNoReceive rnr = new ReceiverNoReceive();
        ReceiverNonPayableFallback rnp = new ReceiverNonPayableFallback();

        console.log("contract | gol, 0 wei | gol, 1 ether | selector necunoscut, 0 wei | selector necunoscut, 1 ether");

        string[4] memory x;
        x = row("Receiver", address(r));
        check(x, "receive", "receive", "fallback", "fallback");
        x = row("OnlyFallback", address(f));
        check(x, "fallback", "fallback", "fallback", "fallback");
        x = row("NoReceive", address(n));
        check(x, "revert", "revert", "revert", "revert");
        x = row("Receiver fara receive", address(rnr));
        check(x, "fallback", "fallback", "fallback", "fallback");
        x = row("Receiver cu fallback non-payable", address(rnp));
        check(x, "receive", "receive", "fallback", "revert");
    }

    function check(string[4] memory got, string memory a, string memory b, string memory c, string memory d) internal pure {
        assertEq(got[0], a);
        assertEq(got[1], b);
        assertEq(got[2], c);
        assertEq(got[3], d);
    }

    // ---------------- 1.2 ----------------

    function test_1_2_Echo() public {
        Echo echo = new Echo();

        (bool ok, bytes memory ret) = address(echo).call(hex"12345678");
        assertTrue(ok);
        assertEq(ret, hex"12345678");                       // exact aceiasi 4 bytes, nu 96 de bytes ABI

        bytes memory depositCalldata = abi.encodeWithSignature("deposit()");
        (ok, ret) = address(echo).call(depositCalldata);
        assertEq(ret, hex"d0e30db0");                       // selectorul lui deposit()

        console.log("ret pentru 0x12345678, lungime:", ret.length);
        console.log("daca ar fi fost ABI-encodat ca bytes, lungimea ar fi:", abi.encode(hex"12345678").length);
    }

    // ---------------- 1.3 ----------------

    function test_1_3_ForceSendToNoReceive() public {
        NoReceive n = new NoReceive();

        (bool ok,) = address(n).call{value: 1 ether}("");
        assertFalse(ok);                                    // transferul normal e refuzat
        assertEq(address(n).balance, 0);

        new ForceSend{value: 1 ether}(address(n));          // selfdestruct in constructor
        assertEq(address(n).balance, 1 ether);              // a primit ether fara sa execute vreo linie de cod
        console.log("balanta NoReceive dupa ForceSend:", address(n).balance);
    }

    // ---------------- 1.4 ----------------

    function test_1_4_AttackerWithReceiveNoLongerReenters() public {
        VulnerableAuction auction = new VulnerableAuction();
        vm.prank(alice);
        auction.placeBid{value: 5 ether}();
        vm.prank(bob);
        auction.placeBid{value: 2 ether}();
        vm.prank(mallory);
        AttackerWithReceive attacker = new AttackerWithReceive(address(auction));
        vm.prank(mallory);
        attacker.bid{value: 1 ether}();
        auction.endAuction();

        vm.prank(mallory);
        attacker.attack();                                  // nu da revert, dar nu mai fura nimic

        console.log("balanta licitatie:", address(auction).balance);
        console.log("balanta attacker :", address(attacker).balance);
        assertEq(address(attacker).balance, 1 ether);       // doar propria oferta
        assertEq(address(auction).balance, 7 ether);        // Alice + Bob raman in licitatie
    }
}
