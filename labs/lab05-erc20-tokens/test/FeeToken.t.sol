// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FeeToken} from "../src/FeeToken.sol";

// Ex 2
contract FeeTokenTest is Test {
    FeeToken fee;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        fee = new FeeToken(owner, 1_000_000 ether);
        vm.prank(owner);
        fee.mint(alice, 100 ether);
    }

    // mint fara taxa: alice are exact 100, owner 0
    function test_MintHasNoFee() public view {
        assertEq(fee.balanceOf(alice), 100 ether);
        assertEq(fee.balanceOf(owner), 0);
    }

    function test_TransferPaysOnePercent() public {
        vm.prank(alice);
        fee.transfer(bob, 10 ether);

        assertEq(fee.balanceOf(bob), 9.9 ether);
        assertEq(fee.balanceOf(owner), 0.1 ether);
        assertEq(fee.balanceOf(alice), 90 ether);
    }

    // un transfer emite DOUA event-uri Transfer: taxa si restul
    function test_TransferEmitsTwoEvents() public {
        vm.expectEmit(true, true, false, true, address(fee));
        emit Transfer(alice, owner, 0.1 ether);
        vm.expectEmit(true, true, false, true, address(fee));
        emit Transfer(alice, bob, 9.9 ether);
        vm.prank(alice);
        fee.transfer(bob, 10 ether);
    }

    // burn fara taxa
    function test_BurnHasNoFee() public {
        vm.prank(alice);
        fee.burn(10 ether);
        assertEq(fee.balanceOf(alice), 90 ether);
        assertEq(fee.balanceOf(owner), 0);
        assertEq(fee.totalSupply(), 90 ether);
    }

    // owner-ul nu plateste taxa catre el insusi
    function test_OwnerTransfersHaveNoFee() public {
        vm.prank(owner);
        fee.mint(owner, 10 ether);
        vm.prank(owner);
        fee.transfer(bob, 10 ether);
        assertEq(fee.balanceOf(bob), 10 ether);
    }

    // transferFrom trece tot prin _update, deci plateste si el taxa
    function test_TransferFromAlsoPaysFee() public {
        vm.prank(alice);
        fee.approve(bob, 10 ether);
        vm.prank(bob);
        fee.transferFrom(alice, bob, 10 ether);
        assertEq(fee.balanceOf(bob), 9.9 ether);
        assertEq(fee.balanceOf(owner), 0.1 ether);
    }

    // sub 100 de unitati, taxa se rotunjeste la 0
    function test_SmallTransferNoFee() public {
        vm.prank(alice);
        fee.transfer(bob, 99);
        assertEq(fee.balanceOf(bob), 99);
        assertEq(fee.balanceOf(owner), 0);
    }

    // FUZZ: pentru orice suma pe care Alice o are
    function testFuzz_TransferFee(uint256 amount) public {
        amount = bound(amount, 0, 100 ether);

        vm.prank(alice);
        assertTrue(fee.transfer(bob, amount));

        assertEq(fee.totalSupply(), 100 ether);                  // supply-ul nu se schimba
        assertEq(fee.balanceOf(bob), amount - amount / 100);     // destinatarul primeste exact atat
        assertEq(fee.balanceOf(owner), amount / 100);            // owner-ul primeste taxa
        assertEq(fee.balanceOf(alice), 100 ether - amount);      // Alice plateste exact amount
    }
}
