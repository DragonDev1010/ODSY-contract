const { assert } = require('chai')

const Nft = artifacts.require('./Nft.sol')
const Trade = artifacts.require('./Trade.sol')
const Odsy = artifacts.require('./Odsy.sol')
const WEth = artifacts.require('./WrapEth.sol')

contract('Trade contract', (accounts) => {
    let nft, trade, odsy, weth, tx
    before(async() => {
        nft = await Nft.deployed()
        trade = await Trade.deployed()
        odsy = await Odsy.deployed()
        weth = await WEth.deployed()
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
        await trade.buy(0, {from: accounts[9], value: web3.utils.toWei('1', 'ether')})
    })

    it('accept offering in wrap ether', async() => {
        let owner = accounts[1]
        let buyer = accounts[4]
        // mint nft by owner
        let hash_, sale, currency, price, royalty
        hash_ = "QmPAd7oqiiCqi7Z6LRWzaz8vhZeJT4jxmckWWeXydJsQwu"
        sale = 0 // {0:'sale', 1:'auction'}
        currency = 0 // {0:'native', 1:'erc20'}
        price = web3.utils.toWei('1', 'ether')
        royalty = 3 // 3%
        tx = await nft.mint(hash_, sale, currency, price, royalty, {from: owner})

        let mintedTokenId = tx.logs[0].args.tokenId.toString()

        // approve minted nft for buying
        await nft.approve(trade.address, Number(mintedTokenId), {from: owner})
        
        // Make an offer lower price by buyer
        let offerPrice = web3.utils.toWei('0.5', 'ether') // offering price
        await weth.mint(web3.utils.toWei('1000', 'ether'), {from: buyer}) // give $WETH to buyer
        await weth.approve(trade.address, offerPrice, {from: buyer}) // approve $WETH to trade contract
        
        // owner set wrapETH address
        await trade.setWrapEthAddr(weth.address, {from: accounts[0]})
        // owner accepts offering of buyer 
        await trade.acceptOffer(mintedTokenId, offerPrice, buyer, {from: owner})
    })

    it('accept offering in odsy', async() => {
        let owner = accounts[1]
        let buyer = accounts[4]
        // mint nft by owner
        let hash_, sale, currency, price, royalty
        hash_ = "QmPAd7oqiiCqi7Z6LRWzaz8vhZeJT4jxmckWWeXydJsQwu"
        sale = 0 // {0:'sale', 1:'auction'}
        currency = 1 // {0:'native', 1:'erc20'}
        price = web3.utils.toWei('1', 'ether')
        royalty = 3 // 3%
        tx = await nft.mint(hash_, sale, currency, price, royalty, {from: owner})

        let mintedTokenId = tx.logs[0].args.tokenId.toString()

        // approve minted nft for buying
        await nft.approve(trade.address, Number(mintedTokenId), {from: owner})
        
        // Make an offer lower price by buyer
        let offerPrice = web3.utils.toWei('0.5', 'ether') // offering price
        await odsy.mint(web3.utils.toWei('1000', 'ether'), {from: buyer}) // give $WETH to buyer
        await odsy.approve(trade.address, offerPrice, {from: buyer}) // approve $WETH to trade contract
        
        // owner set wrapETH address
        await trade.setWrapEthAddr(odsy.address, {from: accounts[0]})
        // owner accepts offering of buyer 
        await trade.acceptOffer(mintedTokenId, offerPrice, buyer, {from: owner})
    })
})