// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {FidelityToken} from "../src/FidelityToken.sol";
import {FidelityPoints, NonTransferableFidelityToken} from "../src/FidelityPoints.sol";

// Ex 1
contract FidelityPointsTest is Test {
    FidelityPoints fp;
    FidelityToken fpt;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant CAP = 1_000_000 ether;

    function setUp() public {
        fp = new FidelityPoints(10, CAP);       // 1 punct = 10 (unitati de valoare)
        fpt = fp.token();
        fp.addPoints(alice, 100 ether);         // 100 de puncte
    }

    function test_TokenOwnedByProgram() public view {
        assertEq(fpt.owner(), address(fp));
        assertEq(fpt.symbol(), "FPT");
    }

    // addPoints = mint
    function test_AddPointsMints() public {
        vm.expectEmit(true, true, false, true, address(fpt));
        emit Transfer(address(0), bob, 30 ether);   // mint: from = 0
        fp.addPoints(bob, 30 ether);

        assertEq(fpt.balanceOf(bob), 30 ether);
        assertEq(fpt.totalSupply(), 130 ether);  // inlocuieste totalPoints
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function test_RevertWhen_NotOwnerAddsPoints() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        fp.addPoints(alice, 1 ether);
    }

    // nici direct pe token nu poate da mint altcineva
    function test_RevertWhen_ClientMintsDirectly() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        fpt.mint(alice, 1 ether);
    }

    // spendPoints = burnFrom, are nevoie de approve
    function test_RevertWhen_SpendWithoutApprove() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(fp), 0, 10 ether)
        );
        fp.spendPoints(10 ether);
    }

    function test_SpendPointsBurns() public {
        vm.startPrank(alice);
        fpt.approve(address(fp), 10 ether);
        fp.spendPoints(10 ether);
        vm.stopPrank();

        assertEq(fpt.balanceOf(alice), 90 ether);
        assertEq(fpt.totalSupply(), 90 ether);      // tokenii au fost distrusi
        assertEq(fpt.allowance(alice, address(fp)), 0);
    }

    function test_RevertWhen_SpendMoreThanBalance() public {
        vm.startPrank(alice);
        fpt.approve(address(fp), 200 ether);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 100 ether, 101 ether)
        );
        fp.spendPoints(101 ether);
        vm.stopPrank();
    }

    function test_GetTotalValue() public view {
        assertEq(fp.getTotalValue(alice), 100 * 10);    // 100 puncte x 10
    }

    function test_RevertWhen_CapExceeded() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, CAP + 100 ether, CAP));
        fp.addPoints(bob, CAP);                         // 100 + CAP > CAP
    }

    // RISCUL NOU: punctele se pot transfera / vinde intre clienti
    function test_Risk_PointsCanBeTransferredAndSpentByOthers() public {
        vm.prank(alice);
        fpt.transfer(bob, 100 ether);                   // Alice "vinde" toate punctele lui Bob

        vm.startPrank(bob);                             // Bob nu a cumparat nimic de la magazin,
        fpt.approve(address(fp), 100 ether);            // dar foloseste punctele castigate de Alice
        fp.spendPoints(100 ether);
        vm.stopPrank();

        assertEq(fpt.balanceOf(alice), 0);
        assertEq(fpt.totalSupply(), 0);
    }

    // varianta fara transferuri: mint si burn merg, transferul nu
    function test_NonTransferableVariant() public {
        NonTransferableFidelityToken nt = new NonTransferableFidelityToken(address(this), CAP);
        nt.mint(alice, 10 ether);

        vm.prank(alice);
        vm.expectRevert(NonTransferableFidelityToken.PointsNotTransferable.selector);
        nt.transfer(bob, 1 ether);

        vm.prank(alice);
        nt.burn(1 ether);                               // burn e permis (to = 0)
        assertEq(nt.balanceOf(alice), 9 ether);
    }
}
