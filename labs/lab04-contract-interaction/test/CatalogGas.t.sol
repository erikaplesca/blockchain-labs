// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";

// Ex. 5.6: apeluri directe, ca decreaseStock și getProducts să apară în gas report
contract CatalogGasTest is Test {
    Catalog cat;

    function setUp() public {
        cat = new Catalog();
        cat.addProduct("P001", "Coffee mug", 55, 3);
        cat.addProduct("P002", "Tea cup", 30, 0);
        cat.addProduct("P003", "T-shirt", 120, 5);
    }

    function test_DecreaseStock() public {
        cat.decreaseStock("P003", 1);                   // admin-ul (contractul de test) are voie
    }

    function test_GetProductsInStock() public view {
        assertEq(cat.getProducts(true, false).length, 2);   // P002 are stoc 0
    }
}
