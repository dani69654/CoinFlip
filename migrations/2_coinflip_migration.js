const CoinFlip = artifacts.require("CoinFlip");

module.exports = async (_deployer) => { 
    _deployer.deploy(CoinFlip);
};
