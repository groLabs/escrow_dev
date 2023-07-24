// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IEscrow.sol";

contract GroEscrow is IEscrow, Ownable {
    struct Escrow {
        address token;
        uint256 amount;
        uint256 length;
    }

    mapping(bytes32 => Escrow) private _deposits;
    mapping(address => uint256) private _depositNonce;

    event Deposited(address indexed payee, address token, uint256 weiAmount);

    constructor() Ownable() {}

    function hashEscrowPosition(
        address payee,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(payee, nonce));
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

        bytes32 position = hashEscrowPosition(payee, _depositNonce[payee]);
        _deposits[position] = Escrow(token, amount, length);
        _depositNonce[payee]++;

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Deposited(payee, token, amount);
        return position;
    }
}
