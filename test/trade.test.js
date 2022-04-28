const { assert } = require('chai')

const Nft = artifacts.require('./Nft.sol')
const Trade = artifacts.require('./Trade.sol')

contract('Trade contract', (accounts) => {
    let nft, trade, tx
    before(async() => {
        nft = await Nft.deployed()
        trade = await Trade.deployed()
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

    // it('try buying non-exist nft', async() => {
    //     try {
    //         await trade.buy(10)
    //     } catch (e) {
    //         console.log(e.reason)
    //     }
    // })

    // it('try buying nft without approving', async() => {
    //     try {
    //         await trade.buy(0)
    //     } catch (e) {
    //         console.log(e.reason)
    //     }
    // })

    it('buy nft in native token', async() => {
        try { await trade.buy(1) } catch (error) { console.log(error.reason) }

        try {
            await trade.buy(0, {from: accounts[9], value: web3.utils.toWei('0.5', 'ether')})
        } catch (e) { console.log(e.reason) }

        try {
            await trade.buy(0, {value: web3.utils.toWei('1', 'ether')})
        } catch (e) { console.log(e.reason) }

        try {
            await trade.buy(0, {from: accounts[9], value: web3.utils.toWei('1', 'ether')})
        } catch (e) { console.log(e.reason) }

        await nft.approve(trade.address, 0)
        let bal_0 = await web3.eth.getBalance(accounts[0])
        let bal_9 = await web3.eth.getBalance(accounts[9])
        console.log(bal_0, bal_9)
        await trade.buy(0, {from: accounts[9], value: web3.utils.toWei('1', 'ether')})
        bal_0 = await web3.eth.getBalance(accounts[0])
        bal_9 = await web3.eth.getBalance(accounts[9])
        console.log(bal_0, bal_9)
    })
})