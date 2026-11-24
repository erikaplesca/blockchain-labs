// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.36;

import "forge-std/Test.sol";
import "../src/FidelityPoints.sol";
import "../src/FidelityPointsRequire.sol";

// Ex. 7.4: custom errors vs require cu mesaj, pe un apel care face revert
contract RequireVsErrorTest is Test {
    FidelityPoints withErrors;
    FidelityPointsRequire withRequire;
    address client = makeAddr("client");

    function setUp() public {
        withErrors = new FidelityPoints(10);
        withRequire = new FidelityPointsRequire(10);
        withErrors.addPoints(client, 100);
        withRequire.addPoints(client, 100);
    }

    function revertGas(address target, bytes memory data) internal returns (uint gasUsed, bytes memory ret) {
        vm.prank(client);
        bool ok;
        (ok, ret) = target.call(data);
        assertFalse(ok);
        gasUsed = vm.lastFrameGas().gasTotalUsed;
    }

    // clientul încearcă addPoints (doar admin-ul are voie)
    function test_RevertGas_NotAdmin() public {
        bytes memory data = abi.encodeWithSignature("addPoints(address,uint256)", client, 10);
        (uint gE, bytes memory rE) = revertGas(address(withErrors), data);
        (uint gR, bytes memory rR) = revertGas(address(withRequire), data);
        console.log("NotAdmin(address)  - gas:", gE, " bytes revert data:", rE.length);
        console.log("require 'Not admin' - gas:", gR, " bytes revert data:", rR.length);
    }

    // clientul cheltuie mai mult decât are
    function test_RevertGas_InsufficientPoints() public {
        bytes memory data = abi.encodeWithSignature("spendPoints(uint256)", 1000);
        (uint gE, bytes memory rE) = revertGas(address(withErrors), data);
        (uint gR, bytes memory rR) = revertGas(address(withRequire), data);
        console.log("InsufficientPoints(uint,uint) - gas:", gE, " bytes revert data:", rE.length);
        console.log("require 'Insufficient points' - gas:", gR, " bytes revert data:", rR.length);
    }
}
