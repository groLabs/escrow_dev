// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IEscrow.sol";
import "./common/SignatureDecoder.sol";

contract GroEscrow is IEscrow, SignatureDecoder, Ownable {
    struct Escrow {
        bool claimed;
        address token;
        uint256 amount;
        uint256 start;
        uint256 length;
    }

    mapping(bytes32 => Escrow) private _deposits;
    mapping(address => uint256) private _depositNonce;

    event Deposited(address indexed payee, address token, uint256 amount);
    event Claimed(address indexed payee, address token, uint256 amount);

    constructor() Ownable() {}

    function hashEscrowPosition(
        address payee,
        address payer,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(payee, payer, nonce));
    }

    function deposit(
        address token,
        address payee,
        uint256 amount,
        uint256 length
    ) external returns (bytes32) {
        require(token != address(0), "ZERO_ADDRESS");
        require(payee != address(0), "ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");

        bytes32 position = hashEscrowPosition(
            payee,
            msg.sender,
            _depositNonce[payee]
        );
        _deposits[position] = Escrow(
            false,
            token,
            amount,
            block.timestamp,
            length
        );
        _depositNonce[payee]++;

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Deposited(payee, token, amount);
        return position;
    }

    /// TODO: Implement arbiter's logic
    /// TODO:
    function claim(
        address token,
        address payee,
        address payer,
        uint256 nonce,
        bytes memory signatures
    ) external {
        require(token != address(0), "ZERO_ADDRESS");
        require(payee != address(0), "ZERO_ADDRESS");
        require(payer != address(0), "ZERO_ADDRESS");
        // Check that the signatures are valid
        if (!_checkSignatures(token, payee, payer, nonce, signatures)) {
            revert("INVALID_SIGNATURES");
        }
        // Do some checks first, such as the escrow exists and is ready to be claimed
        bytes32 escrowPosition = hashEscrowPosition(payee, payer, nonce);

        Escrow memory escrow = _deposits[escrowPosition];
        if (escrow.amount == 0 || escrow.claimed) {
            revert("ESCROW_CLAIMED or ESCROW_DOES_NOT_EXIST");
        }
        // Check that the escrow is ready to be claimed
        if (escrow.start + escrow.length > block.timestamp) {
            revert("TOO_EARLY");
        }
        // Mark the escrow as claimed
        _deposits[escrowPosition].claimed = true;
        // Transfer the funds to the payee
        IERC20(escrow.token).transfer(payee, escrow.amount);
        emit Claimed(payee, escrow.token, escrow.amount);
    }

    /// @notice Checks if the provided signature is valid for the provided data
    /// @notice and that is signed by either the sender or the payee
    /// TODO: Implement smart contract signatures check
    /// TODO: EIP1271 support
    function _checkSignatures(
        address token,
        address payee,
        address payer,
        uint256 nonce,
        bytes memory signatures
    ) internal view returns (bool) {
        bytes32 messageHash = encodeMessage(
            token,
            payee,
            payer,
            nonce,
            CLAIM_TYPEHASH
        );
        (uint8 v1, bytes32 r1, bytes32 s1) = signatureSplit(signatures, 0);
        (uint8 v2, bytes32 r2, bytes32 s2) = signatureSplit(signatures, 1);
        address signer1 = ecrecover(messageHash, v1, r1, s1);
        address signer2 = ecrecover(messageHash, v2, r2, s2);
        return
            (signer1 == payee || signer1 == payer) &&
            (signer2 == payee || signer2 == payer);
    }
}
