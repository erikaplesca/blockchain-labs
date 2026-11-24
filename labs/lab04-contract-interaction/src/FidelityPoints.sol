// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

// Ex. 1.1: doar funcțiile din Catalog de care are nevoie FidelityPoints
interface ICatalog {
    function getPrice(bytes32 code) external view returns (uint);
    function decreaseStock(bytes32 code, uint amount) external;
}

contract FidelityPoints {

    address public immutable admin;                           // Ex. 7.1: în bytecode, nu în storage
    bool public paused;                                       // Ex. 3.1; Ex. 7.1: singur în slotul 0, offset 0
    uint public pointValue;

    mapping(address => uint) public points;

    uint totalPoints;

    ICatalog public catalog;                                  // Ex. 1.1 (slot 4)

    // Ex. 1.6: câte un contor pentru fiecare clauză catch
    uint public nbFailedError;                                // catch Error(string)
    uint public nbFailedPanic;                                // catch Panic(uint)
    uint public nbFailedRevert;                               // catch (bytes)

    error NotAdmin(address caller);
    error InsufficientPoints(uint required, uint available);  // Ex. 1.2
    error CatalogNotSet();                                    // Ex. 1.2
    error ProgramPaused();                                    // Ex. 3.1
    error ProgramNotPaused();                                 // Ex. 3.1
    error ZeroAmount();                                       // Ex. 3.2 (înlocuiește ZeroQuantity din Ex. 1.2)
    error LengthMismatch();                                   // Ex. 7.3

    // Ex. 2.1
    event PointsAdded(address indexed client, uint amount);
    event PointsSpent(address indexed client, uint amount);
    event PointValueChanged(uint oldValue, uint newValue);
    event PointsRedeemed(address indexed client, bytes32 indexed code, uint quantity, uint pointsSpent);
    event RedemptionFailed(address indexed client, bytes32 indexed code, bytes reason);

    // Ex. 3.5: corpul modifier-ului e mutat într-o funcție internal
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
    }

    // Ex. 3.1
    modifier whenNotPaused() {
        if (paused) revert ProgramPaused();
        _;
    }

    // Ex. 3.1
    modifier whenPaused() {
        if (!paused) revert ProgramNotPaused();
        _;
    }

    // Ex. 3.2: modifier cu argument
    modifier validAmount(uint amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    constructor(uint _pointValue) {
        admin = msg.sender;
        pointValue = _pointValue;
    }

    // Ex. 3.3: ordinea modifiers contează: primul care eșuează dă eroarea
    function addPoints(address client, uint _points) public onlyAdmin whenNotPaused validAmount(_points) {
        points[client] += _points;
        updateTotalPoints(_points, true);
        emit PointsAdded(client, _points);                    // Ex. 2.1
    }

    // Ex. 7.3: puncte pentru mai mulți clienți într-o singură tranzacție; totalPoints scris o singură dată
    function addPointsBatch(address[] calldata clients, uint[] calldata amounts) external onlyAdmin whenNotPaused {
        if (clients.length != amounts.length) revert LengthMismatch();
        uint sum;
        for (uint i = 0; i < clients.length; i++) {
            uint amount = amounts[i];
            if (amount == 0) revert ZeroAmount();
            points[clients[i]] += amount;
            sum += amount;
            emit PointsAdded(clients[i], amount);
        }
        updateTotalPoints(sum, true);                         // un singur SSTORE pe totalPoints
    }

    // Ex. 7.3: aceeași funcție cu parametri memory, doar pentru comparația de gas
    function addPointsBatchMemory(address[] memory clients, uint[] memory amounts) external onlyAdmin whenNotPaused {
        if (clients.length != amounts.length) revert LengthMismatch();
        uint sum;
        for (uint i = 0; i < clients.length; i++) {
            uint amount = amounts[i];
            if (amount == 0) revert ZeroAmount();
            points[clients[i]] += amount;
            sum += amount;
            emit PointsAdded(clients[i], amount);
        }
        updateTotalPoints(sum, true);
    }

    function spendPoints(uint _points) external whenNotPaused validAmount(_points) {
        uint available = points[msg.sender];                  // Ex. 7.2: o singură citire din storage
        if (available < _points) revert InsufficientPoints(_points, available);
        uint remaining;
        unchecked {
            remaining = available - _points;                  // Ex. 7.2: nu poate face underflow, available >= _points
        }
        points[msg.sender] = remaining;
        updateTotalPoints(_points, false);
        assert(totalPoints >= remaining);                     // Ex. 3.4: invariant (fără a reciti points)
        emit PointsSpent(msg.sender, _points);                // Ex. 2.1
    }

    // Ex. 3.1: valoarea punctului se poate schimba doar cât timp programul e pe pauză
    function setPointValue(uint _pointValue) public onlyAdmin whenPaused {
        emit PointValueChanged(pointValue, _pointValue);      // Ex. 2.1
        pointValue = _pointValue;
    }

    // Ex. 3.1
    function pause() external onlyAdmin {
        paused = true;
    }

    // Ex. 3.1
    function unpause() external onlyAdmin {
        paused = false;
    }

    // Ex. 1.1
    function setCatalog(address _catalog) external onlyAdmin {
        catalog = ICatalog(_catalog);
    }

    // Ex. 1.2: checks - effects - interactions
    // Ex. 1.6: un eșec al decreaseStock nu mai anulează tranzacția; se returnează false
    function redeem(bytes32 code, uint quantity) external whenNotPaused validAmount(quantity) returns (bool) {
        // checks
        if (address(catalog) == address(0)) revert CatalogNotSet();
        uint cost = catalog.getPrice(code) * quantity;
        uint required = (cost + pointValue - 1) / pointValue;   // rotunjire în sus
        uint available = points[msg.sender];
        if (available < required) revert InsufficientPoints(required, available);

        // effects
        uint remaining;
        unchecked {
            remaining = available - required;                 // Ex. 7.2: verificat mai sus, available >= required
        }
        points[msg.sender] = remaining;
        updateTotalPoints(required, false);
        assert(totalPoints >= remaining);                     // Ex. 3.4: invariant (fără a reciti points)

        // interactions
        // Ex. 2.1: reason = error data completă (ABI), aceeași formă pentru toate cele 3 clauze
        bytes memory reason;
        try catalog.decreaseStock(code, quantity) {
            emit PointsRedeemed(msg.sender, code, quantity, required);   // Ex. 2.1
            return true;
        } catch Error(string memory message) {
            nbFailedError += 1;                                // require / revert("...")
            reason = abi.encodeWithSignature("Error(string)", message);
        } catch Panic(uint errorCode) {
            nbFailedPanic += 1;                                // overflow, assert, ...
            reason = abi.encodeWithSignature("Panic(uint256)", errorCode);
        } catch (bytes memory lowLevelData) {
            nbFailedRevert += 1;                               // custom errors
            reason = lowLevelData;
        }
        emit RedemptionFailed(msg.sender, code, reason);      // Ex. 2.1

        // Ex. 1.6: decreaseStock a eșuat, deci restitui punctele clientului
        points[msg.sender] += required;
        updateTotalPoints(required, true);
        return false;
    }

    function getTotalValue(address client) public view returns (uint totalValue) {
        totalValue = points[client] * pointValue;
    }

    function getTotalPoints() external view returns (uint) {
        return totalPoints;
    }

    function updateTotalPoints(uint _points, bool added) internal {
        if (added) {
            totalPoints += _points;
        } else {
            // Ex. 7.2: sigur, pentru că totalPoints >= points[client] >= _points (verificat de apelant)
            unchecked {
                totalPoints -= _points;
            }
        }
    }
}
