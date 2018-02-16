var Migrations = artifacts.require("./CryptologiQ.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
