// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

contract Catalog {

    enum State { Active, Expired }

    struct Promo{
        State state;
        uint start;
        uint end;
        uint percent;
    }

    struct Product{
        bytes32 code;
        string description;
        uint price;
        bool inStock;
        uint stock;
    }

    Product[] public products;
    Promo public generalPromo;
    address admin;

    mapping(bytes32 => Promo) public productPromos;

    error ProductNotFound(bytes32 code);
    error InvalidPercent(uint percent);

    constructor(){
        admin = msg.sender;
    }

    function addProduct(bytes32 code, string memory description, uint price, uint stock) public {
        products.push(Product({
            code: code,
            description: description,
            price: price,
            inStock: stock > 0,
            stock: stock
        }));
    }

    function increaseStock(bytes32 code, uint amount) external {
        Product storage p = products[findProduct(code)];
        p.stock += amount;
        p.inStock = p.stock > 0;
    }

    function decreaseStock(bytes32 code, uint amount) external {
        Product storage p = products[findProduct(code)];
        p.stock -= amount;
        p.inStock = p.stock > 0;
    }

    function findProduct(bytes32 code) internal view returns (uint) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].code == code) {
                return i;
            }
        }
        revert ProductNotFound(code);
    }

    function startPromo(uint ndays, uint percent) external{
        generalPromo = newPromo(ndays, percent);
    }

    function endPromo() external {
        generalPromo.end = block.timestamp;
        generalPromo.state = State.Expired;
    }

    function startProductPromo(bytes32 code, uint ndays, uint percent) public {
        findProduct(code);
        productPromos[code] = newPromo(ndays, percent);
    }

    function startPromoBatch(bytes32[] calldata codes, uint ndays, uint percent) external {
        for (uint i = 0; i < codes.length; i++) {
            startProductPromo(codes[i], ndays, percent);
        }
    }

    function newPromo(uint ndays, uint percent) internal view returns (Promo memory) {
        if (percent > 100) revert InvalidPercent(percent);
        return Promo({
            start: block.timestamp,
            end: block.timestamp + (ndays * 24 * 60 * 60),
            state: State.Active,
            percent: percent
        });
    }

    function isActive(Promo memory promo) internal view returns (bool) {
        return promo.state == State.Active && block.timestamp >= promo.start && block.timestamp < promo.end;
    }

    function hasActivePromo(bytes32 code) public view returns (bool) {
        return isActive(productPromos[code]) || isActive(generalPromo);
    }

    function currentDiscount(bytes32 code) public view returns (uint percent) {
        if (isActive(productPromos[code])) {
            percent = productPromos[code].percent;
        }
        if (isActive(generalPromo) && generalPromo.percent > percent) {
            percent = generalPromo.percent;
        }
    }

    function getPrice(bytes32 code) external view returns (uint) {
        Product storage p = products[findProduct(code)];
        return discountedPrice(p.price, currentDiscount(code));
    }

    function getProducts(bool inStock, bool inPromo) public view returns (Product[] memory) {
        uint count = 0;
        for (uint i = 0; i < products.length; i++) {
            if (matches(products[i], inStock, inPromo)) {
                count++;
            }
        }

        Product[] memory result = new Product[](count);
        uint j = 0;
        for (uint i = 0; i < products.length; i++) {
            if (matches(products[i], inStock, inPromo)) {
                result[j] = products[i];
                j++;
            }
        }
        return result;
    }

    function matches(Product storage p, bool inStock, bool inPromo) internal view returns (bool) {
        return (!inStock || p.inStock) && (!inPromo || hasActivePromo(p.code));
    }

    function discountedPrice(uint price, uint percent) public pure returns (uint) {
        if (percent > 100) revert InvalidPercent(percent);
        return price * (100 - percent) / 100;
    }
}
