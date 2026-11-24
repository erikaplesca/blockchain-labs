// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";

// Ex. 6.4: costul lui getProducts(false, false) și varianta cu paginare
// rulează cu: forge test --match-contract GetProductsTest -vv
contract GetProductsTest is Test {
    Catalog cat;
    uint constant N = 100;
    uint constant TX_GAS_LIMIT = 16_777_216;           // 2^24, limita de gas per tranzacție

    function code(uint i) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked("P", vm.toString(i)));
    }

    function addProducts(uint from, uint to) internal {
        for (uint i = from; i <= to; i++) {
            cat.addProduct(code(i), "Product", 10, 5);
        }
    }

    function setUp() public {
        cat = new Catalog();
        addProducts(1, N);
    }

    function gasOfGetProductsAll() internal view returns (uint) {
        cat.getProducts{gas: 30_000_000}(false, false);   // peste limită, ca să pot măsura și la 1.600
        return vm.lastFrameGas().gasTotalUsed;
    }

    // costul pentru 100 de produse, apoi cum crește odată cu catalogul
    function test_GetProductsAllGas() public {
        console.log("getProducts(false, false), 100 produse :", gasOfGetProductsAll());

        uint[5] memory sizes = [uint(200), 500, 1000, 1500, 1600];
        uint n = N;
        for (uint k = 0; k < sizes.length; k++) {
            addProducts(n + 1, sizes[k]);
            n = sizes[k];
            uint g = gasOfGetProductsAll();
            console.log("produse:", n);
            console.log("    gas:", g, g > TX_GAS_LIMIT ? "  > LIMITA 16.777.216" : "");
        }
    }

    // paginare: pagini de 10
    function test_Pagination() public view {
        Catalog.Product[] memory page = cat.getProducts(0, 10);
        assertEq(page.length, 10);
        assertEq(page[0].code, code(1));
        assertEq(page[9].code, code(10));

        page = cat.getProducts(95, 10);                 // doar 5 au rămas
        assertEq(page.length, 5);
        assertEq(page[4].code, code(100));

        assertEq(cat.getProducts(100, 10).length, 0);   // offset la final
        assertEq(cat.getProducts(500, 10).length, 0);   // offset dincolo de final
        assertEq(cat.getProducts(0, type(uint).max).length, N);   // limit uriaș, fără overflow
    }

    function test_PaginationGas() public {
        cat.getProducts(0, 10);
        console.log("getProducts(0, 10), 100 produse       :", vm.lastFrameGas().gasTotalUsed);
        addProducts(N + 1, 2 * N);
        cat.getProducts(0, 10);
        console.log("getProducts(0, 10), 200 produse       :", vm.lastFrameGas().gasTotalUsed);
    }
}
