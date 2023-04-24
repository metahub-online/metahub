import hre from 'hardhat'

const {ethers, upgrades} = hre

// const {address} = require("hardhat/internal/core/config/config-validation");

async function deployNft(name, symbol, uri) {

    const TxnHubBasicGiftCardNFT = await ethers.getContractFactory('TxnHubBasicGiftCardNFTV2')
    const giftCardNft = await TxnHubBasicGiftCardNFT.deploy(name, symbol, uri)
    console.log(giftCardNft)
    await giftCardNft.deployed()
    const txHash = giftCardNft.deployTransaction.hash
    console.log('GiftCard contract address=' + giftCardNft.address + ', txhash=' + txHash)
    const txReceipt = await ethers.provider.waitForTransaction(txHash)
    // console.log('Contract deployed to address:', contractAddress)
    // await giftCardNft.setApprovalForAll(marketAddress, true)
    // //create list
    // const GfpMarketPlace = await ethers.getContractFactory('GfpMarketPlace')
    // const market = await GfpMarketPlace.attach(marketAddress)
    // market.createList(contractAddress, 1, 5, 4000, ethers.utils.parseEther('0.1'))

    return txReceipt.contractAddress
}


deployNft('TxnHubGiftCard','TXNCARD', 'https://polygon.txnhub.io/contracts/giftcard/tokens/{id}/metadata.json')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })