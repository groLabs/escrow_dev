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
        bytes memory signatures,
        uint256 pos
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
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
