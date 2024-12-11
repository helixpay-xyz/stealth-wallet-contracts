// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "openzeppelin/proxy/Clones.sol";

import "./StealthWallet.sol";

contract StealthWalletFactory {
    address public immutable stealthWalletImplementation;

    constructor(address entryPoint) {
        stealthWalletImplementation = address(new StealthWallet(entryPoint));
    }

    function createStealthWallet(address signer) external returns (address) {
        return Clones.cloneDeterministic(stealthWalletImplementation, keccak256(abi.encodePacked(signer)));
    }

    function getStealthWalletAddress(address signer) external view returns (address) {
        return Clones.predictDeterministicAddress(stealthWalletImplementation, keccak256(abi.encodePacked(signer)));
    }
}
