import hre from 'hardhat'

const {ethers, upgrades} = hre

// const {address} = require("hardhat/internal/core/config/config-validation");


async function upgradeMarketSupport(contract, address) {
    const ContractObj = await ethers.getContractFactory(contract)
    const contractInstance = await upgrades.upgradeProxy(address, ContractObj)
    await contractInstance.deployed()
    return contractInstance
}

upgradeMarketSupport('TxnSaleMarketV0', '0x1faFe2e2b97acd11CBcacA053816b5af9EBA7EDE')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })