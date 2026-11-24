// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract MyERC20Test is Test {
    MyERC20 internal token;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        token = new MyERC20(owner);
        vm.prank(owner);
        token.mint(alice, 100 ether);
    }

    function test_Metadata() public view {
        assertEq(token.name(), "Fidelity Points");
        assertEq(token.symbol(), "FPT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
    }

    function test_Mint_ByOwner() public {
        vm.prank(owner);
        token.mint(bob, 25 ether);

        assertEq(token.balanceOf(bob), 25 ether);
        assertEq(token.totalSupply(), 125 ether);
    }

    function test_Mint_RevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.mint(alice, 1 ether);
    }

    function test_Transfer() public {
        vm.prank(alice);
        token.transfer(bob, 40 ether);

        assertEq(token.balanceOf(alice), 60 ether);
        assertEq(token.balanceOf(bob), 40 ether);
    }

    function test_ApproveAndTransferFrom() public {
        vm.prank(alice);
        token.approve(bob, 30 ether);

        vm.prank(bob);
        token.transferFrom(alice, bob, 20 ether);

        assertEq(token.balanceOf(bob), 20 ether);
        assertEq(token.allowance(alice, bob), 10 ether);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 10 ether, 11 ether)
        );
        token.transferFrom(alice, bob, 11 ether);
    }
}
