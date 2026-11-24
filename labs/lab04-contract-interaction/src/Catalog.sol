// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

contract Catalog {

    enum State { Active, Expired }

    // Ex. 5.2: packing - toate câmpurile într-un singur slot (1 + 5 + 5 + 1 = 12 bytes)
    struct Promo{
        State state;
        uint40 start;
        uint40 end;
        uint8 percent;
    }

    // Ex. 5.2: packing - price și stock împart al treilea slot (16 + 8 = 24 bytes)
    // Ex. 5.6: inStock eliminat, se calculează ca stock > 0
    struct Product{
        bytes32 code;
        string description;
        uint128 price;
        uint64 stock;
    }

    Product[] public products;
    Promo public generalPromo;
    address admin;

    mapping(bytes32 => Promo) public productPromos;

    address public fidelityProgram;                 // Ex. 1.3 (slot 4 după packing)

    // Ex. 6.2: poziția fiecărui produs în products, PLUS UNU (0 = produsul nu există)
    // declarat la final, ca să nu mute sloturile variabilelor de mai sus
    mapping(bytes32 => uint) productIndex;          // slot 5

    error ProductNotFound(bytes32 code);
    error InvalidPercent(uint percent);
    error NotAdmin(address caller);                 // Ex. 1.3
    error NotAuthorized(address caller);            // Ex. 1.3
    error ValueTooLarge(uint value, uint max);      // Ex. 5.4
    error DuplicateProduct(bytes32 code);           // Ex. 6.2

    // Ex. 2.2
    event ProductAdded(bytes32 indexed code, uint price, uint stock);
    event StockChanged(bytes32 indexed code, uint newStock);
    event PromoStarted(bytes32 indexed code, uint end, uint percent);
    event ProductRemoved(bytes32 indexed code);                         // Ex. 6.3   // code = bytes32(0) pentru promoția generală

    // Ex. 1.3
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        _;
    }

    // Ex. 1.3: decreaseStock poate fi apelat doar de admin sau de programul de fidelitate
    modifier onlyAdminOrFidelityProgram() {
        if (msg.sender != admin) {
            require(fidelityProgram != address(0), "Fidelity program not set");   // Error(string)
            if (msg.sender != fidelityProgram) revert NotAuthorized(msg.sender);  // custom error
        }
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    // Ex. 1.3
    function setFidelityProgram(address _fidelityProgram) external onlyAdmin {
        fidelityProgram = _fidelityProgram;
    }

    function addProduct(bytes32 code, string memory description, uint price, uint stock) public {
        // Ex. 5.4: uint128(price) / uint64(stock) ar păstra doar biții de jos, fără nicio eroare
        if (price > type(uint128).max) revert ValueTooLarge(price, type(uint128).max);
        if (stock > type(uint64).max) revert ValueTooLarge(stock, type(uint64).max);
        if (productIndex[code] != 0) revert DuplicateProduct(code);   // Ex. 6.2
        products.push(Product({
            code: code,
            description: description,
            price: uint128(price),                      // Ex. 5.2
            stock: uint64(stock)                        // Ex. 5.2
        }));
        productIndex[code] = products.length;           // Ex. 6.2: noua poziție (length - 1) + 1
        emit ProductAdded(code, price, stock);          // Ex. 2.2
    }

    function increaseStock(bytes32 code, uint amount) external {
        Product storage p = products[findProduct(code)];
        uint newStock = p.stock + amount;               // Ex. 5.4: adunarea se face pe uint (256 biți)
        if (newStock > type(uint64).max) revert ValueTooLarge(newStock, type(uint64).max);
        p.stock = uint64(newStock);                     // sigur: newStock <= max
        emit StockChanged(code, p.stock);               // Ex. 2.2
    }

    function decreaseStock(bytes32 code, uint amount) external onlyAdminOrFidelityProgram {
        Product storage p = products[findProduct(code)];
        p.stock = uint64(p.stock - amount);             // Ex. 5.4: scăderea pe uint, fără să trunchiez amount
        emit StockChanged(code, p.stock);               // Ex. 2.2
    }

    // Ex. 6.3: swap and pop - ultimul produs ia locul celui șters, apoi array-ul se scurtează
    function removeProduct(bytes32 code) external onlyAdmin {
        uint index = findProduct(code);                 // revert ProductNotFound dacă nu există
        uint lastIndex = products.length - 1;
        if (index != lastIndex) {
            Product storage moved = products[lastIndex];
            products[index] = moved;                    // copiere storage -> storage (inclusiv string-ul)
            productIndex[moved.code] = index + 1;       // produsul mutat are o poziție nouă
        }
        products.pop();                                 // șterge ultimul element (sloturile lui devin 0)
        delete productIndex[code];                      // codul poate fi adăugat din nou
        delete productPromos[code];                     // promoția produsului șters
        emit ProductRemoved(code);
    }

    // Ex. 6.2: o singură citire din mapping în loc de o buclă peste tot array-ul
    function findProduct(bytes32 code) internal view returns (uint) {
        uint index = productIndex[code];
        if (index == 0) revert ProductNotFound(code);
        return index - 1;
    }

    function startPromo(uint ndays, uint percent) external{
        generalPromo = newPromo(ndays, percent);
        emit PromoStarted(bytes32(0), generalPromo.end, percent);              // Ex. 2.2
    }

    function endPromo() external {
        generalPromo.end = uint40(block.timestamp);     // Ex. 5.2
        generalPromo.state = State.Expired;
    }

    function startProductPromo(bytes32 code, uint ndays, uint percent) public {
        findProduct(code);
        productPromos[code] = newPromo(ndays, percent);
        emit PromoStarted(code, productPromos[code].end, percent);             // Ex. 2.2
    }

    function startPromoBatch(bytes32[] calldata codes, uint ndays, uint percent) external {
        for (uint i = 0; i < codes.length; i++) {
            startProductPromo(codes[i], ndays, percent);
        }
    }

    function newPromo(uint ndays, uint percent) internal view returns (Promo memory) {
        if (percent > 100) revert InvalidPercent(percent);
        return Promo({
            start: uint40(block.timestamp),                          // Ex. 5.2
            end: uint40(block.timestamp + (ndays * 24 * 60 * 60)),   // Ex. 5.2
            state: State.Active,
            percent: uint8(percent)                                  // Ex. 5.2 (percent <= 100, verificat mai sus)
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

    // Ex. 6.4: paginare - cel mult `limit` produse, începând de la poziția `offset`
    // costul depinde de `limit`, nu de numărul total de produse
    function getProducts(uint offset, uint limit) public view returns (Product[] memory result) {
        uint length = products.length;
        if (offset >= length) return new Product[](0);
        uint end = limit > length - offset ? length : offset + limit;   // fără overflow pentru limit uriaș
        result = new Product[](end - offset);
        for (uint i = offset; i < end; i++) {
            result[i - offset] = products[i];
        }
    }

    // Ex. 5.6: p.stock > 0 în loc de p.inStock
    function matches(Product storage p, bool inStock, bool inPromo) internal view returns (bool) {
        return (!inStock || p.stock > 0) && (!inPromo || hasActivePromo(p.code));
    }

    function discountedPrice(uint price, uint percent) public pure returns (uint) {
        if (percent > 100) revert InvalidPercent(percent);
        return price * (100 - percent) / 100;
    }
}
