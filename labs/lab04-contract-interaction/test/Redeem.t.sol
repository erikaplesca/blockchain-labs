// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";
import "../src/FidelityPoints.sol";

// Ex. 4: teste pentru integrarea FidelityPoints - Catalog
contract RedeemTest is Test {
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

    // helper: stocul produsului de pe poziția i (getter-ul public al structului returnează toate câmpurile)
    // Ex. 5.2/5.6: câmpurile sunt code, description, price, stock (inStock eliminat la 5.6)
    function stockOf(uint i) internal view returns (uint stock) {
        (,,, stock) = cat.products(i);
    }

    // 4.1 un redeem reușit actualizează punctele, totalPoints și stocul și emite PointsRedeemed
    function test_RedeemUpdatesStateAndEmitsEvent() public {
        vm.expectEmit(true, true, false, true, address(fp));
        emit FidelityPoints.PointsRedeemed(client, "P001", 1, 6);

        vm.prank(client);
        bool ok = fp.redeem("P001", 1);

        assertTrue(ok);
        assertEq(fp.points(client), 94);
        assertEq(fp.getTotalPoints(), 94);
        assertEq(stockOf(0), 2);
    }

    // 4.2 rotunjirea în sus: preț 55, pointValue 10 => 6 puncte; promoția de 20% => preț 44 => 5 puncte
    function test_PointsRoundedUpAndPromoReducesThem() public {
        vm.prank(client);
        fp.redeem("P001", 1);
        assertEq(fp.points(client), 100 - 6);           // 55 / 10 = 5,5 -> 6

        cat.startProductPromo("P001", 7, 20);
        assertEq(cat.getPrice("P001"), 44);

        vm.prank(client);
        fp.redeem("P001", 1);
        assertEq(fp.points(client), 100 - 6 - 5);       // 44 / 10 = 4,4 -> 5
    }

    // 4.3 puncte insuficiente: InsufficientPoints(required, available) cu valorile corecte
    function test_RevertWhen_InsufficientPoints() public {
        // 20 bucăți x 55 = 1100 -> 110 puncte necesare, clientul are 100
        vm.expectRevert(abi.encodeWithSelector(FidelityPoints.InsufficientPoints.selector, 110, 100));
        vm.prank(client);
        fp.redeem("P001", 20);
    }

    // 4.4 un client nu poate apela decreaseStock direct pe catalog
    function test_RevertWhen_ClientCallsDecreaseStock() public {
        vm.expectRevert(abi.encodeWithSelector(Catalog.NotAuthorized.selector, client));
        vm.prank(client);
        cat.decreaseStock("P001", 1);
    }

    // 4.5 cantitate mai mare decât stocul: false, punctele restituite, contorul Panic incrementat
    function test_RedeemMoreThanStockReturnsFalse() public {
        vm.prank(client);
        bool ok = fp.redeem("P001", 4);                  // stoc 3 -> underflow în decreaseStock

        assertFalse(ok);
        assertEq(fp.points(client), 100);
        assertEq(fp.getTotalPoints(), 100);
        assertEq(fp.nbFailedPanic(), 1);
        assertEq(stockOf(0), 3);
    }

    // 4.6 addPoints, spendPoints și redeem fac revert cât timp programul e pe pauză
    function test_RevertWhen_Paused() public {
        fp.pause();

        vm.expectRevert(FidelityPoints.ProgramPaused.selector);
        fp.addPoints(client, 10);

        vm.expectRevert(FidelityPoints.ProgramPaused.selector);
        vm.prank(client);
        fp.spendPoints(10);

        vm.expectRevert(FidelityPoints.ProgramPaused.selector);
        vm.prank(client);
        fp.redeem("P001", 1);
    }
}
