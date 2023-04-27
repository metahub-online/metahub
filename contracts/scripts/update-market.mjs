import hre from 'hardhat'
import chainConfigs from "./chain-configs.mjs";

const {ethers, upgrades} = hre

// const {address} = require("hardhat/internal/core/config/config-validation");



async function upgradeMarket(chain) {
    const chainCfg = chainConfigs[chain]
    const marketAddr = chainCfg.market
    // const TxnHubMarketv2 = await ethers.getContractFactory('TxnSimpleMarketV2')
    const TxnHubMarketv3 = await ethers.getContractFactory('TxnSimpleMarketV4')
    // const marketExistsContract = await upgrades.forceImport(marketAddr, TxnHubMarketv2)
    const marketPlace = await upgrades.upgradeProxy(marketAddr, TxnHubMarketv3)
    // const marketPlace = await upgrades.upgradeProxy(marketExistsContract, TxnHubMarketv3)
    await marketPlace.deployed()
    return marketPlace
}

upgradeMarket('polygon')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })