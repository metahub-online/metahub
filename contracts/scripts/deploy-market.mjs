import chainMarkets from "./chain-configs.mjs";

async function deployMarket(chain) {
    const chainConfig = chainMarkets[chain]
    if (chainConfig == null) {
        throw 'not found config on chain ' + chain
    }
    let roleManagerContract = chainConfig.roleManager
    let mintableMarket = chainConfig.mintable
    let saleMarket = chainConfig.salemarket
    let exchangeRateContract = chainConfig.exchange.pricefeed
    let inverse = chainConfig.exchange.inverse
    let chainDigits = chainConfig.exchange.digits
    const TxnHubMarket = await ethers.getContractFactory('TxnSimpleMarketV2')
    const marketPlace = await upgrades.deployProxy(TxnHubMarket, [roleManagerContract, mintableMarket, saleMarket, exchangeRateContract, inverse, chainDigits], {initializer: 'initialize'})
    await marketPlace.deployed()
    return marketPlace
}

//Goerli: ETH/USD:  0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
//PolygonMumbai:  MATIC/USD:   0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
//Ethereum:  ETH/USD:  0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
//PlatOnDev: LAT/USD:  0xCfbdA7E553038a34b1ea1f84DEB3667A73dF8FEe
//RoleManager: 0xF6a49Cb529d8b254348C318B46B2E817ebe76fc9  ETH:0xcd49519Fe366fD0e7D09e8C3C7DaF0dd3643DBDf
//mintableMarket: 0x711d6367298DeF5639F6740c90dc07fE285F90E3 ETH:0x029f7d6574de83587c997D0C52fe7e7B01E7a87E
//saleMarket: 0x1faFe2e2b97acd11CBcacA053816b5af9EBA7EDE ETH:0x778ED761D6d5322Ee0aE6018C3b9262EC9d0F1fd
deployMarket('platon')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })