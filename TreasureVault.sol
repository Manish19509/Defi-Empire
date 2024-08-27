// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20Burnable.sol";
import "./GoldToken.sol";
import "./GemToken.sol";

contract TreasureVault {
    using SafeMath for uint;

    GoldToken public goldToken;
    GemToken public gemToken;
    uint public constant goldMiningRate = 10;

    address public immutable contractOwner;
    mapping(address => bool) public isMiningActive;
    mapping(address => uint) public miningStartTime;
    mapping(address => uint) public goldBalance;
    mapping(address => uint) public gemBalance;
    mapping(address => uint) public stakedGold;

    enum CardRarity {Rare, SuperRare, Epic, Mythic, Legendary}

    struct PlayerInventory {
        uint rareCards;
        uint superRareCards;
        uint epicCards;
        uint mythicCards;
        uint legendaryCards;
    }

    mapping(address => PlayerInventory) public playerInventory;

    constructor(address _goldToken, address _gemToken) {
        goldToken = GoldToken(_goldToken);
        gemToken = GemToken(_gemToken);
        contractOwner = msg.sender;
    }

    function startMining() public {
        miningStartTime[msg.sender] = block.timestamp;
        isMiningActive[msg.sender] = true;
    }

    function calculateMiningRewards() public view returns (uint) {
        require(isMiningActive[msg.sender], "Mining is not active");
        uint totalMiningTime = block.timestamp - miningStartTime[msg.sender];
        uint earnedGold = goldMiningRate * totalMiningTime;
        return earnedGold;
    }

    function claimGoldRewards() public {
        require(isMiningActive[msg.sender], "Mining has not started");
        uint totalMiningTime = block.timestamp - miningStartTime[msg.sender];
        uint earnedGold = goldMiningRate * totalMiningTime;

        goldBalance[msg.sender] += earnedGold;
        miningStartTime[msg.sender] = block.timestamp;
    }

    function engageInBattle() public {
        require(goldBalance[msg.sender] >= 20, "Insufficient gold balance");
        goldBalance[msg.sender] -= 20;
        uint randomOutcome = block.timestamp % 10;
        if (randomOutcome % 2 == 0) {
            // Won the battle
            goldBalance[msg.sender] += 100;
        }
    }

    function tradeGoldForGems(uint goldAmount) public {
        require(stakedGold[msg.sender] == 0, "Previous trade not settled, withdraw gems first");
        require(goldAmount > 0, "Gold amount must be greater than zero");
        stakedGold[msg.sender] += goldAmount;
        bool success = goldToken.transferFrom(contractOwner, address(this), goldAmount);
        require(success, "Gold transfer failed");
        goldBalance[msg.sender] -= goldAmount;
    }

    function withdrawGems() public {
        require(stakedGold[msg.sender] > 0, "No staked gold available");
        uint gemAmount = stakedGold[msg.sender] / 10;
        stakedGold[msg.sender] = 0;
        bool success = gemToken.transferFrom(contractOwner, msg.sender, gemAmount);
        require(success, "Gem withdrawal failed");
        gemBalance[msg.sender] += gemAmount;
    }

    function transferGems(address recipient, uint amount) public {
        require(recipient != address(0), "Invalid recipient address");
        require(gemToken.balanceOf(msg.sender) >= amount, "Insufficient gem tokens");

        gemToken.approve(address(this), amount);
        bool success = gemToken.transferFrom(msg.sender, recipient, amount);
        require(success, "Gem transfer failed");
        gemBalance[recipient] += amount;
    }

    function redeemCard(CardRarity rarity) public {
        if (rarity == CardRarity.Rare) {
            require(gemBalance[msg.sender] >= 10, "Not enough gems");
            playerInventory[msg.sender].rareCards += 1;
            gemToken.burn(10, msg.sender);
            gemBalance[msg.sender] -= 10;
        } else if (rarity == CardRarity.SuperRare) {
            require(gemBalance[msg.sender] >= 20, "Not enough gems");
            playerInventory[msg.sender].superRareCards += 1;
            gemToken.burn(20, msg.sender);
            gemBalance[msg.sender] -= 20;
        } else if (rarity == CardRarity.Epic) {
            require(gemBalance[msg.sender] >= 30, "Not enough gems");
            playerInventory[msg.sender].epicCards += 1;
            gemToken.burn(30, msg.sender);
            gemBalance[msg.sender] -= 30;
        } else if (rarity == CardRarity.Mythic) {
            require(gemBalance[msg.sender] >= 40, "Not enough gems");
            playerInventory[msg.sender].mythicCards += 1;
            gemToken.burn(40, msg.sender);
            gemBalance[msg.sender] -= 40;
        } else if (rarity == CardRarity.Legendary) {
            require(gemBalance[msg.sender] >= 50, "Not enough gems");
            playerInventory[msg.sender].legendaryCards += 1;
            gemToken.burn(50, msg.sender);
            gemBalance[msg.sender] -= 50;
        } else {
            revert("Invalid card rarity selected");
        }
    }
}
