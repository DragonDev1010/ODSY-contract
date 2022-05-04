const Odsy = artifacts.require("Odsy")
const WEth = artifacts.require("WrapEth")
const Nft = artifacts.require("Nft");
const Trade = artifacts.require('Trade')
const Auction = artifacts.require('Auction')

const {nfts} = require('../database/nfts')

module.exports = async function (deployer, network, accounts) {
	await deployer.deploy(Odsy, "Odsy", 'ODSY')
	await deployer.deploy(WEth)
	await deployer.deploy(Nft);
	await deployer.deploy(Trade, Nft.address, Odsy.address)
	await deployer.deploy(Auction, Nft.address, Odsy.address)
	
	const nft = await Nft.deployed()
	const odsy = await Odsy.deployed()
	const weth = await WEth.deployed()

	// mint test NFTs by `accounts[0]`
	for(let i = 0 ; i < nfts.length ; i++) {
		const nftPrice = web3.utils.toWei(nfts[i].price.toString(), 'ether')
		await nft.mint(nfts[i].ipfsHash, nfts[i].saleMethod, nfts[i].curType, nftPrice, nfts[i].royalty)
	}
	
	// mint $ODSY and $WETH to all accounts
	for (let i = 0 ; i < 10 ; i++) {
		await odsy.mint(web3.utils.toWei('1000', 'ether'), {from: accounts[i]})
		await weth.mint(web3.utils.toWei('1000', 'ether'), {from: accounts[i]})
	}
};