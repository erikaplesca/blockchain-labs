// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FidelityToken} from "./FidelityToken.sol";

// Ex 1 - FidelityPoints din Lab 2/3, dar punctele sunt acum tokeni ERC-20 (FPT)
// inainte: mapping points, totalPoints, updateTotalPoints, getTotalPoints, admin + onlyAdmin + NotAdmin
// acum: token.balanceOf, token.totalSupply, Ownable
contract FidelityPoints is Ownable {
    FidelityToken public immutable token;
    uint256 public pointValue;              // valoarea unui punct INTREG (1 FPT = 10^18 unitati)

    event PointsSpent(address indexed client, uint256 amount);

    constructor(uint256 _pointValue, uint256 cap) Ownable(msg.sender) {
        pointValue = _pointValue;
        // FidelityPoints e owner-ul tokenului, deci doar el poate face mint
        token = new FidelityToken(address(this), cap);
    }

    function addPoints(address client, uint256 amount) external onlyOwner {
        token.mint(client, amount);
    }

    // clientul trebuie sa dea intai token.approve(address(fidelityPoints), amount)
    function spendPoints(uint256 amount) external {
        token.burnFrom(msg.sender, amount);
        emit PointsSpent(msg.sender, amount);
    }

    function setPointValue(uint256 _pointValue) external onlyOwner {
        pointValue = _pointValue;
    }

    function getTotalValue(address client) external view returns (uint256) {
        return token.balanceOf(client) * pointValue / 10 ** token.decimals();
    }
}

// Ex 1 (in plus) - varianta in care punctele NU se pot transfera intre clienti
// doar mint (from = 0) si burn (to = 0) sunt permise
contract NonTransferableFidelityToken is FidelityToken {
    error PointsNotTransferable();

    constructor(address initialOwner, uint256 cap_) FidelityToken(initialOwner, cap_) {}

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) revert PointsNotTransferable();
        super._update(from, to, value);
    }
}
