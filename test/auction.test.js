const { assert } = require("chai")

const Odsy = artifacts.require('./Odsy.sol')
const Nft = artifacts.require('./Nft.sol')
const Auction = artifacts.require('./Auction.sol')

contract('Auction contract', (accounts) => {
    let odsy, nft, auction, tx
    
    function delayFunc(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function getIntervalToStart(tokenId) {
        let auctionDetail = await auction.auctionList(tokenId)
        let auctionStart = auctionDetail.startAt.toString()

        let now = new Date()
        let nowStamp = now.getTime()

        return (Number(auctionStart)*1000 - Number(nowStamp) + 1000)
    }

    async function getIntervalToEnd(tokenId) {
        let auctionDetail = await auction.auctionList(tokenId)
        let auctionEnd = auctionDetail.endAt.toString()

        let now = new Date()
        let nowStamp = now.getTime()

        return (Number(auctionEnd)*1000 - Number(nowStamp) + 1000)
    }

    before(async() => {
        odsy = await Odsy.deployed()
        nft = await Nft.deployed()
        auction = await Auction.deployed()
    })

    it('mint nft', async() => {
        let hash_, sale, currency, price, royalty

        hash_ = "QmPAd7oqiiCqi7Z6LRWzaz8vhZeJT4jxmckWWeXydJsQwu"
        sale = 0 // {0:'sale', 1:'auction'}
        currency = 0 // {0:'native', 1:'erc20'}
        price = web3.utils.toWei('1', 'ether')
        royalty = 3 // 3%
        await nft.mint(hash_, sale, currency, price, royalty)

        hash_ = "QmPAd7oqiiCqi7Z6LRWzaz8vhZeJT4jxmckWWeXydJsQwu"
        sale = 1 // {0:'sale', 1:'auction'}
        currency = 0 // {0:'native', 1:'erc20'}
        price = web3.utils.toWei('1', 'ether')
        royalty = 3 // 3%
        await nft.mint(hash_, sale, currency, price, royalty)
    })

    it('open auction', async() => {
        let now = new Date()
        let currentStamp = now.getTime()
        let delay_1 = currentStamp + 5 * 1000 // 5 second
        let delay_2 = currentStamp + 10 * 1000 // 10 second

        let tokenId, startPrice, startAt, endAt

        tokenId = 0
        startPrice = web3.utils.toWei('1', 'ether')
        startAt = Math.floor(delay_1 / 1000)
        endAt = Math.floor(delay_2 / 1000)
        await nft.approve(auction.address, tokenId)

        try {
            await auction.openAuction(2, startPrice, startAt, endAt)
        } catch (e) { console.log(e.reason) }

        try {
            let testStartAt = Math.floor((now.setDate(now.getDate() - 1)) / 1000)
            await auction.openAuction(0, startPrice, testStartAt, endAt)
        } catch (e) { console.log(e.reason) }

        try {
            let testStart = Math.floor((now.getTime() + 2*60*1000) / 1000)
            let testEnd = Math.floor((now.getTime() + 60*1000) / 1000)
            await auction.openAuction(0, startPrice, testStart, testEnd)
        } catch (e) { console.log(e.reason) }
        
        await auction.openAuction(0, startPrice, startAt, endAt)

        try {
            await auction.openAuction(0, startPrice, startAt, endAt)
        } catch (e) { console.log(e.reason) }
    })

    it('place a bid', async() => {
        let tokenId = 0

        try {
            await auction.placeBid(tokenId, web3.utils.toWei('1', 'ether'), {value: web3.utils.toWei('1', 'ether')})
        } catch (e) { console.log(e.reason) } // Auction is not yet started

        let delay = await getIntervalToStart(tokenId)
        await delayFunc(delay);

        try {
            await auction.placeBid(tokenId, web3.utils.toWei('1', 'ether'), {from: accounts[3], value: web3.utils.toWei('1', 'ether')})
        } catch (e) { console.log(e.reason) } // Bid price has to be greater than the previous highest bid price

        try {
            await auction.placeBid(tokenId, web3.utils.toWei('1.2', 'ether'), {value: web3.utils.toWei('1.2', 'ether')})
        } catch (e) { console.log(e.reason) } // Auction creator can not place the bid.

        await auction.placeBid(tokenId, web3.utils.toWei('1.2', 'ether'), {from: accounts[3],value: web3.utils.toWei('1.2', 'ether')})
        tx = await web3.eth.getBalance(accounts[3])

        // 1.2 ETH is withdrawed to `accounts[3]`
        await auction.placeBid(tokenId, web3.utils.toWei('1.3', 'ether'), {from: accounts[2],value: web3.utils.toWei('1.3', 'ether')})
        tx = await web3.eth.getBalance(accounts[3])

        delay = await getIntervalToEnd(tokenId)
        await delayFunc(delay)

        try {
            await auction.placeBid(tokenId, web3.utils.toWei('1', 'ether'), {value: web3.utils.toWei('1', 'ether')})
        } catch (e) { console.log(e.reason) } // Auction is already ended.
    })

    it('complete auction', async() => {
        let tokenId = 0
        let preNftOwner = await nft.ownerOf(tokenId)
        console.log('Previous NFT Owner: ', preNftOwner)
        let preOwnerEth = await web3.eth.getBalance(preNftOwner)
        console.log('Old owner balance: ', web3.utils.fromWei(preOwnerEth, 'ether'))
        let auctionEth = await web3.eth.getBalance(auction.address)
        console.log('Auction contract balance: ', web3.utils.fromWei(auctionEth, 'ether'))
        
        await auction.completeAuction(0)
        
        let curNftOwner = await nft.ownerOf(tokenId)
        console.log('Current NFT Owner: ', curNftOwner)
        preOwnerEth = await web3.eth.getBalance(preNftOwner)
        console.log('Old owner balance: ', web3.utils.fromWei(preOwnerEth, 'ether'))
        auctionEth = await web3.eth.getBalance(auction.address)
        console.log('Auction contract balance: ', web3.utils.fromWei(auctionEth, 'ether'))
    })
})