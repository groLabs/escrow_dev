// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title SignatureDecoder - Decodes signatures encoded as bytes
 */
abstract contract SignatureDecoder {
    bytes32 public DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(address token, address payee, address payer, uint256 nonce)"
        );

    bytes32 public constant REFUND_TYPEHASH =
        keccak256(
            "Refund(address token, address payee, address payer, uint256 nonce)"
        );

    function signatureSplit(
        bytes memory packedSignatures,
        uint256 position
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 signatureSize = 65; // Size of a single signature (v + r + s) in bytes
        require(
            packedSignatures.length >= (position + 1) * signatureSize,
            "Invalid position"
        );

        assembly {
            // Load the signature data from the packedSignatures array
            let dataPointer := add(
                packedSignatures,
                mul(signatureSize, position)
            )

            // Load v (1 byte)
            v := byte(0, mload(dataPointer))

            // Load r (32 bytes, starting from 33rd byte)
            r := mload(add(dataPointer, 0x21))

            // Load s (32 bytes, starting from 65th byte)
            s := mload(add(dataPointer, 0x41))
        }
    }

    function encodeMessage(
        bytes32 typeHash,
        address token,
        address payee,
        address payer,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, block.chainid, address(this))
        );
        bytes32 structHash = keccak256(
            abi.encode(typeHash, token, payee, payer, nonce)
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return messageHash;
    }
}
