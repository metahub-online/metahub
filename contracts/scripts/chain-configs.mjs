const chainMarkets = {
    eth: {
        market: '0x0979021a0c3369101beC659660442F16E5fEbB47',
        roleManager: '0xcd49519Fe366fD0e7D09e8C3C7DaF0dd3643DBDf',
        mintable: '0x029f7d6574de83587c997D0C52fe7e7B01E7a87E',
        salemarket: '0x778ED761D6d5322Ee0aE6018C3b9262EC9d0F1fd',
        nft: ['0xCD6EbF59E83610574D037F5A0Aa3A09fCa25752C'],
        exchange: {
            pricefeed: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
            inverse: true,
            digits: 18
        }
    },
    goerli: {
        market: '0xc9798e483C867e4591F97f5205FC1fbaCB441Fdd',
        roleManager: '0xF6a49Cb529d8b254348C318B46B2E817ebe76fc9',
        mintable: '0x711d6367298DeF5639F6740c90dc07fE285F90E3',
        salemarket: '0x1faFe2e2b97acd11CBcacA053816b5af9EBA7EDE',
        nft: ['0x94f41341F890b8f0c0e4f5c989948782062e25f1', '0x5C4160BF81431e38D8cB2b8daa44De29c6A75404'],
        exchange: {
            pricefeed: '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e',
            inverse: true,
            digits: 12
        }
    },
    platon: {
        market: '0x689495f139f3664Bc74b52828a4e2c776A2792B7',
        roleManager: '0xC3aF5CaD72dd4346295ff561cdC23f0610591149',
        mintable: '0x50145EBec3a2b3e401512D4a00996e26A8B1279A',
        salemarket: '0xC2d04b00EE8841c74633eC2Ba64787dA449d0041',
        nft: ['0x0f91054783D3273a861f837587fF91695087F862'],
        exchange: {
            pricefeed: '0xCD6EbF59E83610574D037F5A0Aa3A09fCa25752C',
            inverse: true,
            digits: 18
        }
    },
    platondev: {
        market: '0x80a40B27656a1c212bb813456Abbf12fb89894ce',
        roleManager: '0x778ED761D6d5322Ee0aE6018C3b9262EC9d0F1fd',
        mintable: '0x0979021a0c3369101beC659660442F16E5fEbB47',
        salemarket: '0xa0548e113f205Eb9F1B58734E1F0CBDe94280C4d',
        nft: ['0xC3aF5CaD72dd4346295ff561cdC23f0610591149'],
        exchange: {
            pricefeed: '0xCfbdA7E553038a34b1ea1f84DEB3667A73dF8FEe',
            inverse: true,
            digits: 18
        }
    },
    mumbai: {
        market: '0x0979021a0c3369101beC659660442F16E5fEbB47',
        roleManager: '0x7A8863f633db5f3Bd321bab8DF85A8c3A048c194',
        mintable: '0xC3aF5CaD72dd4346295ff561cdC23f0610591149',
        salemarket: '0x50145EBec3a2b3e401512D4a00996e26A8B1279A',
        nft: ['0x689495f139f3664Bc74b52828a4e2c776A2792B7'],
        exchange: {
            pricefeed: '0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada',
            inverse: true,
            digits: 18
        }
    },
    polygon: {
        market: '0x0979021a0c3369101beC659660442F16E5fEbB47',
        roleManager: '0xcd49519Fe366fD0e7D09e8C3C7DaF0dd3643DBDf',
        mintable: '0x029f7d6574de83587c997D0C52fe7e7B01E7a87E',
        salemarket: '0x778ED761D6d5322Ee0aE6018C3b9262EC9d0F1fd',
        nft: ['0x689495f139f3664Bc74b52828a4e2c776A2792B7'],
        exchange: {
            pricefeed: '0xAB594600376Ec9fD91F8e885dADF0CE036862dE0',
            inverse: true,
            digits: 18
        }
    }
}
export default chainMarkets