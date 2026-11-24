// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import {FidelityToken} from "./FidelityToken.sol";

// Ex 2 - la fiecare transfer intre doi clienti, 1% merge la owner
contract FeeToken is FidelityToken {
    constructor(address initialOwner, uint256 cap_) FidelityToken(initialOwner, cap_) {}

    function _update(address from, address to, uint256 value) internal override {
        // mint (from = 0), burn (to = 0) si transferurile owner-ului nu platesc taxa
        if (from == address(0) || to == address(0) || from == owner() || to == owner()) {
            super._update(from, to, value);
            return;
        }
        uint256 fee = value / 100;              // rotunjit in jos: sub 100 de unitati taxa e 0
        super._update(from, owner(), fee);
        super._update(from, to, value - fee);
    }
}
