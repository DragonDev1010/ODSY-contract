require('chai')
    .use(require('chai-as-promised'))
    .should()

const Nft = artifacts.require('./Nft.sol')

contract ('NFT contract', (accounts) => {
    let res, nftContract
    before(async() => {
        nftContract = await Nft.deployed()
    })

    it('initialize', async() => {
        
    })
})