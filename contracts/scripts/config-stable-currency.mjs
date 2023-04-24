import chainMarkets from "./chain-configs.mjs";

const stableCurrencies = {
    'polygon': {
        'USDT': {id: 1, digits: 6, erc20: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F', pricefeed: '0x0A6513e40db6EB1b165753AD52E80663aeA50545', inverse: true},
        'USDC': {id: 2, digits: 6, erc20: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', pricefeed: '0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7', inverse: true}
    }
}

async function configStableCurrency(chain, name) {
    const marketCfg = chainMarkets[chain]
    if (marketCfg == null) {
        throw 'chain config not found ' + chain
    }
    const currencyCfgs = stableCurrencies[chain]
    if (currencyCfgs == null) {
        throw 'currency not configured in chain ' + chain
    }
    const currencyConfig = currencyCfgs[name]
    if (currencyConfig == null) {
        throw 'currency ' + name + ' not configured in chain ' + chain
    }
    const {id, digits, erc20, pricefeed, inverse} = currencyConfig
    let marketAddr = marketCfg.market
    const Market = await ethers.getContractFactory('TxnSimpleMarketV3')
    const market = await Market.attach(marketAddr)
    return await market.configStableCurrency(id, digits, pricefeed, inverse, erc20)
}

async function disableStableCurrency(chain, id) {
    const marketCfg = chainMarkets[chain]
    if (marketCfg == null) {
        throw 'chain config not found ' + chain
    }
    let marketAddr = marketCfg.market
    const Market = await ethers.getContractFactory('TxnSimpleMarketV3')
    const market = await Market.attach(marketAddr)
    return await market.disableStableCurrency(id)
}

configStableCurrency('polygon', 'USDT')
    .then(res => {
        console.log(res)
    }).catch(err => {
    console.log(err)
})