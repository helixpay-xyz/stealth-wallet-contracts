// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/StealthWalletFactory.sol";

contract DeployMagicPayScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envAddress("ENTRY_POINT");

        vm.startBroadcast(deployerPrivateKey);
        StealthWalletFactory factory = new StealthWalletFactory(entryPoint);
        console.log("StealthWalletFactory deployed at: ", address(factory));
        vm.stopBroadcast();
    }
}
