// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "openzeppelin/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

import "account-abstraction/core/BaseAccount.sol";
import "account-abstraction/core/Helpers.sol";

contract StealthWallet is BaseAccount {
    address private immutable _walletImplementAddress;
    IEntryPoint private immutable _entryPoint;
    address private immutable _factory;

    constructor(address entryPointAddress) {
        _entryPoint = IEntryPoint(entryPointAddress);
        _factory = msg.sender;
        _walletImplementAddress = address(this);
    }

    modifier authorized() {
        require(msg.sender == address(entryPoint()), "Caller is not entryPoint");
        _;
    }

    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {

        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(hash, userOp.signature);

        if (address(this) == Clones.predictDeterministicAddress(_walletImplementAddress, keccak256(abi.encodePacked(signer)), _factory)) {
            return SIG_VALIDATION_SUCCESS;
        }

        return SIG_VALIDATION_FAILED;
    }

    function execute(address dest, uint256 value, bytes calldata func) external authorized {
        _call(dest, value, func);
    }

    function executeBatch(address[] calldata dest, uint256[] calldata values, bytes[] calldata func) external authorized {
        require(dest.length == func.length, "Wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], values[i], func[i]);
        }
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }
}
