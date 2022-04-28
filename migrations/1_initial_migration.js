const Odsy = artifacts.require("Odsy")
const Nft = artifacts.require("Nft");
const Trade = artifacts.require('Trade')

module.exports = async function (deployer) {
  await deployer.deploy(Odsy, "Odsy", 'ODSY')
  await deployer.deploy(Nft);
  await deployer.deploy(Trade, Nft.address, Odsy.address)
};
