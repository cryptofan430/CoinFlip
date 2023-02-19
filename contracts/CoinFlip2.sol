//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable {
	struct User {
		uint256 unclaimed; // Current Balance of the user
		uint256 betCount;
		uint256 winningCount;
	}
	uint256[] public probabilities = [6, 4];
	uint256 constant INVERSE_BASIS_POINT = 10;
	address[] usersBetted;
	mapping(address => User) public users;

	event betCompleted(
		address bettor,
		bool status,
		uint256 betAmount,
		uint256 timeStamp
	);
	event userWithdrawal(address indexed caller, uint256 amount);

	constructor() {}

	function rand() internal view returns (uint256) {
		uint256 seed = uint256(
			keccak256(
				abi.encodePacked(
					block.timestamp +
						block.difficulty +
						((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
							(block.timestamp)) +
						block.gaslimit +
						((uint256(keccak256(abi.encodePacked(msg.sender)))) /
							(block.timestamp)) +
						block.number
				)
			)
		);

		return (seed % INVERSE_BASIS_POINT);
	}

	function getPickId() internal view returns (uint256) {
		uint256 value = rand();

		for (uint256 i = probabilities.length - 1; i > 0; i--) {
			uint256 probability = probabilities[i];
			if (value < probability) {
				return i;
			} else {
				value = value - probability;
			}
		}
		return 0;
	}

	function placeBet(bool _betchoice, uint256 timeStamp) external payable {
		uint256 randVal = getPickId();
		bool flipped = (randVal == 1);
		uint256 _betAmount = msg.value;
		users[msg.sender].betCount++;
		if (flipped) {
			users[msg.sender].unclaimed += _betAmount * 2;
			users[msg.sender].winningCount++;
		}
		usersBetted.push(msg.sender);
		emit betCompleted(msg.sender, flipped, _betAmount, timeStamp);
	}

	function claimRewards() external {
		// Can be rewarded only by the Owner
		uint256 amount = users[msg.sender].unclaimed;
		require(amount > 0, "You have no rewards to claim");
		address payable to = payable(msg.sender);
		users[msg.sender].unclaimed = 0;
		to.transfer(amount);

		emit userWithdrawal(msg.sender, amount);
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function addMoney() external payable {}

	function withdraw() external onlyOwner {
		address payable to = payable(msg.sender);
		to.transfer(getBalance());
	}
}
