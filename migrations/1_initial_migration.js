var Migrations = artifacts.require("./CryptologiqContract.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
