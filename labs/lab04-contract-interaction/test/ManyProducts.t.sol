// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";

// Ex. 6.1 / 6.2: costul căutării unui produs într-un catalog cu 100 de produse
// rulează cu: forge test --match-contract ManyProductsTest --isolate -vv
contract ManyProductsTest is Test {
    Catalog cat;
    uint constant N = 100;

    // codul produsului i: "P1", "P2", ..., "P100" (ca bytes32)
    function code(uint i) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked("P", vm.toString(i)));
    }

    function setUp() public {
        cat = new Catalog();
        for (uint i = 1; i <= N; i++) {
            cat.addProduct(code(i), "Product", 10, 5);
        }
    }

    // fiecare măsurătoare în testul ei: Foundry adaugă un cost fix primei măsurători dintr-un test,
    // așa că primul și ultimul produs sunt măsurate în aceleași condiții
    // argumentele se calculează înainte de startSnapshotGas, ca să nu fie incluse în măsurătoare
    function measureDecreaseStock(string memory name, uint i) internal returns (uint gasUsed) {
        Catalog c = cat;
        bytes32 productCode = code(i);
        vm.startSnapshotGas(name);
        c.decreaseStock(productCode, 1);
        gasUsed = vm.stopSnapshotGas();
    }

    function test_DecreaseStockFirst() public {
        console.log("decreaseStock primul produs (P1)   :", measureDecreaseStock("decreaseStock_first", 1));
    }

    function test_DecreaseStockLast() public {
        console.log("decreaseStock ultimul produs (P100):", measureDecreaseStock("decreaseStock_last", N));
    }

    // folosit la 6.2: costul adăugării produsului 101
    function test_AddProduct() public {
        Catalog c = cat;
        bytes32 newCode = code(N + 1);
        vm.startSnapshotGas("addProduct_101");
        c.addProduct(newCode, "Product", 10, 5);
        console.log("addProduct (al 101-lea)            :", vm.stopSnapshotGas());
    }

    // Ex. 6.2: același cod de două ori => DuplicateProduct
    function test_RevertWhen_DuplicateCode() public {
        vm.expectRevert(abi.encodeWithSelector(Catalog.DuplicateProduct.selector, code(7)));
        cat.addProduct(code(7), "Duplicate", 10, 5);
    }

    // Ex. 6.2: un cod inexistent => tot ProductNotFound
    function test_RevertWhen_ProductNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(Catalog.ProductNotFound.selector, code(999)));
        cat.decreaseStock(code(999), 1);
    }
}
