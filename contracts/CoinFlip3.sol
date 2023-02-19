//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip is Ownable {
	struct User {
		uint256 unclaimed; // Current Balance of the user
		uint256 betCount;
		uint256 winningCount;
	}
	uint256[] public probabilities = [60, 40];
	uint256 constant INVERSE_BASIS_POINT = 100;
	uint256 constant DEPOSIT_FEE = 3;
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

	function _random(uint256 seed) internal view returns (uint256) {
		uint256 randomNumber = uint256(
			keccak256(
				abi.encodePacked(blockhash(block.number - 1), msg.sender, seed)
			)
		);
		return randomNumber % INVERSE_BASIS_POINT;
	}

	function getPickId(uint256 timeStamp) internal view returns (uint256) {
		uint256 value = _random(timeStamp);

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
		uint256 randVal = getPickId(timeStamp);
		bool flipped = (randVal == 1);
		uint256 _betAmount = msg.value;
		uint256 _stakedAmount = msg.value * (100 - DEPOSIT_FEE);
		users[msg.sender].betCount++;
		if (flipped) {
			users[msg.sender].unclaimed += _stakedAmount * 2;
			users[msg.sender].winningCount++;
		}
		usersBetted.push(msg.sender);
		emit betCompleted(msg.sender, flipped, _betAmount, timeStamp);
	}

	function claimRewards() external returns (uint256) {
		// Can be rewarded only by the Owner
		uint256 amount = users[msg.sender].unclaimed;
		require(amount > 0, "You have no rewards to claim");
		address payable to = payable(msg.sender);
		users[msg.sender].unclaimed = 0;
		to.transfer(amount);
		emit userWithdrawal(msg.sender, amount);
		return amount;
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
