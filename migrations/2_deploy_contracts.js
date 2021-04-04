var coinFlip = artifacts.require("./CoinFlip.sol");

module.exports = function(deployer) {
  deployer.deploy(coinFlip);
};
