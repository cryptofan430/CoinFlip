const { expect } = require("chai");
const { ethers } = require("hardhat");
const web3 = require('web3');
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("Greeter", function () {
  before(async function () {
    [owner, account1, account2] = await ethers.getSigners();
  });

  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
