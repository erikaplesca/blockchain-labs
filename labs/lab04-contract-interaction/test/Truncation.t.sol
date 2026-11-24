// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/Catalog.sol";

// Ex. 5.4: conversia explicită uint -> uint128 / uint64 trunchiază în tăcere
contract TruncationTest is Test {
    Catalog cat;

    function setUp() public {
        cat = new Catalog();
        cat.addProduct("P001", "Coffee mug", 55, 3);
    }

    // fără verificări: uint128(2**128 + 5) păstrează doar cei 128 de biți de jos => 5, fără revert
    function test_CastTruncatesSilently() public pure {
        uint price = 2**128 + 5;
        assertEq(uint128(price), 5);
        uint stock = 2**64;
        assertEq(uint64(stock), 0);
    }

    function test_RevertWhen_PriceTooLarge() public {
        uint price = uint(type(uint128).max) + 1;
        vm.expectRevert(abi.encodeWithSelector(Catalog.ValueTooLarge.selector, price, type(uint128).max));
        cat.addProduct("P002", "Gold mug", price, 1);
    }

    function test_RevertWhen_StockTooLarge() public {
        uint stock = uint(type(uint64).max) + 1;
        vm.expectRevert(abi.encodeWithSelector(Catalog.ValueTooLarge.selector, stock, type(uint64).max));
        cat.addProduct("P002", "Tea cup", 10, stock);
    }

    function test_RevertWhen_IncreaseStockOverflows() public {
        uint amount = type(uint64).max;                 // 3 + max > max
        vm.expectRevert(abi.encodeWithSelector(Catalog.ValueTooLarge.selector, uint(3) + amount, type(uint64).max));
        cat.increaseStock("P001", amount);
    }

    // valoarea maximă încă este acceptată
    function test_MaxValuesAccepted() public {
        cat.addProduct("P002", "Max", type(uint128).max, type(uint64).max);
        (,, uint128 price, uint64 stock) = cat.products(1);   // Ex. 5.6: 4 câmpuri
        assertEq(price, type(uint128).max);
        assertEq(stock, type(uint64).max);
    }
}
