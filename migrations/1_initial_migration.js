const Odsy = artifacts.require("Odsy")
const Nft = artifacts.require("Nft");
const Trade = artifacts.require('Trade')
const Auction = artifacts.require('Auction')

module.exports = async function (deployer) {
  await deployer.deploy(Odsy, "Odsy", 'ODSY')
  await deployer.deploy(Nft);
  await deployer.deploy(Trade, Nft.address, Odsy.address)
  await deployer.deploy(Auction, Nft.address, Odsy.address)
};
