const { assert } = require('chai')

const Nft = artifacts.require('./Nft.sol')

contract ('NFT contract', (accounts) => {
    let tx, nft
    before(async() => {
        nft = await Nft.deployed()
    })

    it('mint nft', async() => {
        let hash_, sale, currency, price, royalty
        hash_ = "QmPAd7oqiiCqi7Z6LRWzaz8vhZeJT4jxmckWWeXydJsQwu"
        sale = 0 // {0:'sale', 1:'auction'}
        currency = 0 // {0:'native', 1:'erc20'}
        price = web3.utils.toWei('1', 'ether')
        royalty = 3 // 3%
        await nft.mint(hash_, sale, currency, price, royalty)
    })

    it('try updating sale method with non-exist tokne Id', async() => {
        try {
            // Tx failed because tokenId #1 does not exist
            await nft.updateSaleMethod(1, 1)
        } catch (error) {
            console.log(error.reason)
        }
    })

    it('try updating sale method by non-owner', async() => {
        try {
            await nft.updateSaleMethod(0, 1, {from: accounts[9]})
        } catch (error) {
            console.log(error.reason)
        }
    })

    it('try updating sale method with unavailable number', async() => {
        try {
            await nft.updateSaleMethod(0, 5)
        } catch (e) {
            console.log(e.reason)
        }
    })

    it('update sale method', async() => {
        let previous = await nft.nftList.call(0)
        let newSaleMethod = 1
        await nft.updateSaleMethod(0, newSaleMethod)
        let after = await nft.nftList.call(0)

        assert.equal(previous.ipfsHash.toString(), after.ipfsHash.toString(), '')
        assert.equal(newSaleMethod, after.saleOption.toString(), '')
        assert.equal(previous.currencyOption.toString(), after.currencyOption.toString(), '')
        assert.equal(previous.price.toString(), after.price.toString(), '')
        assert.equal(previous.royalty.toString(), after.royalty.toString(), '')
        assert.equal(previous.creator.toString(), after.creator.toString(), '')
        assert.equal(previous.owner.toString(), after.owner.toString(), '')
    })

    it('update price', async() => {
        let newPrice = web3.utils.toWei('2', 'ether')
        let previous = await nft.nftList.call(0)
        await nft.updatePrice(0, newPrice)
        let after = await nft.nftList.call(0)

        assert.equal(previous.ipfsHash.toString(), after.ipfsHash.toString(), '')
        assert.equal(previous.saleOption.toString(), after.saleOption.toString(), '')
        assert.equal(previous.currencyOption.toString(), after.currencyOption.toString(), '')
        assert.equal(newPrice, after.price.toString(), '')
        assert.equal(previous.royalty.toString(), after.royalty.toString(), '')
        assert.equal(previous.creator.toString(), after.creator.toString(), '')
        assert.equal(previous.owner.toString(), after.owner.toString(), '')
    })

    it('check if token exist', async() => {
        tx = await nft.exists(0)
        console.log(tx.toString())
        tx = await nft.exists(1)
        console.log(tx.toString())
    })
})