require('chai')
    .use(require('chai-as-promised'))
    .should()

const Nft = artifacts.require('./Nft.sol')

contract ('NFT contract', (accounts) => {
    let tx, nftContract
    before(async() => {
        nftContract = await Nft.deployed()
    })

    it('mint nft', async() => {
        let hash_ = "0xbec921276c8067fe0c82def3e5ecfd8447f1961bc85768c2a56e6bd26d3c0c53"
        let curOpt = 0 // BNB
        let saleOpt = 0 // Fixed
        let price = 10 
        tx = await nftContract.mint(hash_, curOpt, saleOpt, price)

        console.log(tx.logs[1].args)
    })
})