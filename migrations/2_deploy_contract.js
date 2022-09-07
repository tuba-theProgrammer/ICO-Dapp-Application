const erc20 = artifacts.require("ERC20");

module.exports = function(deployer) {
  deployer.deploy(erc20);
};
