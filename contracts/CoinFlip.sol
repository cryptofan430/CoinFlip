//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CoinFlip {
	struct User {
		uint256 unclaimed; // Current Balance of the user
		uint256 betCount;
		uint256 winningCount;
		bool betStatus; // True if betted, false otherwise
	}
	address[] usersBetted;
	mapping(address => User) public users;

	event betCompleted(address bettor, bool status, uint256 betAmout);
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

		return (seed - ((seed / 1000) * 1000));
	}

	function placeBet(bool _betchoice) external payable {
		uint256 randVal = rand();
		bool flipped = (randVal % 2) == 1;
		uint256 _betAmount = msg.value;
		users[msg.sender].betCount++;
		// uint256 winChoice = uint256(_vrf()) % 2;
		if (flipped == _betchoice) {
			users[msg.sender].unclaimed += _betAmount;
			users[msg.sender].winningCount++;
		}
		usersBetted.push(msg.sender);
		emit betCompleted(msg.sender, flipped == _betchoice, _betAmount);
	}

	function claimRewards() external {
		// Can be rewarded only by the Owner
		uint256 amount = users[msg.sender].unclaimed;
		require(amount > 0, "You have no rewards to claim");
		address payable to = payable(msg.sender);
		users[msg.sender].unclaimed = 0;
		// users[msg.sender].betStatus = false;
		to.transfer(amount);

		emit userWithdrawal(msg.sender, amount);
	}

	function _vrf() private view returns (bytes32 result) {
		uint256[1] memory bn;
		bn[0] = block.number;
		assembly {
			let memPtr := mload(0x40)
			if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
				invalid()
			}
			result := mload(memPtr)
		}
	}
}
