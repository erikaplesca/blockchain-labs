// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";

// Ex. 6.3: removeProduct cu swap and pop
// rulează cu: forge test --match-contract RemoveProductTest --isolate -vv
contract RemoveProductTest is Test {
    Catalog cat;
    uint constant N = 100;

    function code(uint i) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked("P", vm.toString(i)));
    }

    function codeAt(uint i) internal view returns (bytes32 c) {
        (c,,,) = cat.products(i);
    }

    function setUp() public {
        cat = new Catalog();
        for (uint i = 1; i <= N; i++) {
            cat.addProduct(code(i), "Product", 10 * i, 5);
        }
    }

    // ștergerea lui P1: P100 se mută pe poziția 0, array-ul are 99 de elemente
    function test_RemoveFirstSwapsLastIntoItsPlace() public {
        cat.removeProduct(code(1));

        assertEq(codeAt(0), code(100));                 // P100 a luat locul lui P1
        assertEq(cat.getPrice(code(100)), 1000);        // productIndex[P100] actualizat corect
        cat.decreaseStock(code(100), 1);
        (,,, uint64 stock) = cat.products(0);
        assertEq(stock, 4);

        vm.expectRevert(abi.encodeWithSelector(Catalog.ProductNotFound.selector, code(1)));
        cat.getPrice(code(1));                          // P1 nu mai există

        vm.expectRevert();                              // poziția 99 nu mai există (length = 99)
        cat.products(99);
    }

    // ștergerea ultimului produs: doar pop, fără mutare
    function test_RemoveLast() public {
        cat.removeProduct(code(100));
        assertEq(codeAt(98), code(99));
        vm.expectRevert();
        cat.products(99);
    }

    // promoția produsului șters dispare; codul poate fi adăugat din nou
    function test_RemoveDeletesPromoAndAllowsReAdd() public {
        cat.startProductPromo(code(5), 7, 20);
        assertEq(cat.currentDiscount(code(5)), 20);

        cat.removeProduct(code(5));
        (Catalog.State state, uint40 start, uint40 end, uint8 percent) = cat.productPromos(code(5));
        assertEq(uint(state) + start + end + percent, 0);   // toate câmpurile 0

        cat.addProduct(code(5), "Product 5 again", 50, 1);  // nu mai dă DuplicateProduct
        assertEq(cat.currentDiscount(code(5)), 0);           // fără promoția veche
        assertEq(cat.getPrice(code(5)), 50);
    }

    function test_RevertWhen_NotAdminRemoves() public {
        address client = makeAddr("client");
        vm.expectRevert(abi.encodeWithSelector(Catalog.NotAdmin.selector, client));
        vm.prank(client);
        cat.removeProduct(code(1));
    }

    // gas-ul lui removeProduct: vm.lastFrameGas() arată gas-ul consumat de ultimul apel și refund-ul
    function logRemoveGas(string memory label, uint i) internal {
        bytes32 c = code(i);
        cat.removeProduct(c);
        Vm.Gas memory g = vm.lastFrameGas();
        console.log(label);
        console.log("  gas consumat (inainte de refund):", g.gasTotalUsed);
        console.log("  refund                          :", uint(int(g.gasRefunded)));
        console.log("  cost final                      :", g.gasTotalUsed - uint(int(g.gasRefunded)));
    }

    function test_RemoveProductGas_Swap() public {
        logRemoveGas("removeProduct(P1)   - swap and pop", 1);
    }

    function test_RemoveProductGas_PopOnly() public {
        logRemoveGas("removeProduct(P100) - doar pop", N);
    }
}
