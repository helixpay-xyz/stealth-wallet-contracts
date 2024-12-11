// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "account-abstraction/core/EntryPoint.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "../src/StealthWalletFactory.sol";
import "../src/StealthWallet.sol";

contract StealthWalletTest is Test {
    EntryPoint entryPoint;
    StealthWalletFactory walletFactory;

    address payable beneficiary;

    function setUp() public {
        entryPoint = new EntryPoint();
        walletFactory = new StealthWalletFactory(address(entryPoint));
        beneficiary = payable(address(vm.addr(uint256(keccak256("beneficiary")))));
    }

    function signUserOpHash(Vm _vm, uint256 _key, bytes32 hash)
        internal
        pure
        returns (bytes memory signature)
    {
        (uint8 v, bytes32 r, bytes32 s) = _vm.sign(_key, MessageHashUtils.toEthSignedMessageHash(hash));
        signature = abi.encodePacked(r, s, v);
    }

    function testCreateWallet() public {
        uint256 stealthSignerKey = 1;
        address stealthSigner = vm.addr(stealthSignerKey);
        address stealthWallet = walletFactory.getStealthWalletAddress(stealthSigner);

        vm.deal(stealthWallet, 1 ether);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        PackedUserOperation memory op = PackedUserOperation({
            sender: stealthWallet,
            nonce: entryPoint.getNonce(stealthWallet, 0),
            initCode: abi.encodePacked(bytes20(address(walletFactory)), abi.encodeWithSignature("createStealthWallet(address)", stealthSigner)),
            callData: abi.encodeWithSelector(StealthWallet.execute.selector, beneficiary, 1, ""),
            accountGasLimits: bytes32(abi.encodePacked(uint128(2000000), uint128(2000000))),
            preVerificationGas: 1000000,
            gasFees: bytes32(abi.encodePacked(uint128(1), uint128(1))),
            paymasterAndData: hex"",
            signature: hex""
        });

        op.signature = signUserOpHash(vm, stealthSignerKey, entryPoint.getUserOpHash(op));

        ops[0] = op;
        entryPoint.handleOps(ops, beneficiary);
    }
}
