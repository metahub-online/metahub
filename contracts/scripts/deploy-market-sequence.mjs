const contractNames = {
    'rolemanager': 'TxnHubRoleManagerV0',
    'mintable': 'TxnMintableMarketV0',
    'sale': 'TxnSaleMarketV0'
}

async function deploySupportContract(contractId) {
    const contractName = contractNames[contractId]
    if (contractName == null) {
        throw 'not found contract:' + contractId
    }
    console.log('deploying ' + contractName)
    const SupportContract = await ethers.getContractFactory(contractName)
    const contract = await upgrades.deployProxy(SupportContract, [], {initializer: 'initialize'})
    await contract.deployed()
    const txHash = contract.deployTransaction.hash
    console.log('Support ' + contractName + ' contract address=' + contract.address + ', txhash=' + txHash)
    const txReceipt = await ethers.provider.waitForTransaction(txHash)

    return txReceipt.contractAddress
}

async function deployMarketSequence(chainConfig, contractClass, exchangeRateContract, inverse, chainDigits, erc20) {
    for (let supportId of ['rolemanager', 'mintable', 'sale']) {
        if (chainConfig[supportId] == null) {
            let addr = await deploySupportContract(supportId)
            chainConfig[supportId] = addr;
        } else {
            console.log('support contract ' + supportId + ' already exists, skip')
        }
    }
    let roleManagerContract = chainConfig.rolemanager
    let mintableMarket = chainConfig.mintable
    let saleMarket = chainConfig.sale
    console.log('deploying market')
    const TxnHubMarket = await ethers.getContractFactory(contractClass)
    const marketPlace = await upgrades.deployProxy(TxnHubMarket, [roleManagerContract, mintableMarket, saleMarket, exchangeRateContract, inverse, chainDigits], {initializer: 'initialize'})
    await marketPlace.deployed()
    const txHash = marketPlace.deployTransaction.hash
    console.log('Market contract address=' + marketPlace.address + ', txhash=' + txHash)
    const txReceipt = await ethers.provider.waitForTransaction(txHash)

    const marketAddr = txReceipt.contractAddress

    if (erc20 != null) {
        for (let i = 0; i < erc20.length; i++) {
            let token = erc20[i];
            marketPlace.configStableCurrency(i + 1, token.feed, token.inverse, token.contract)
        }
    }
    return {market: marketAddr, supports: chainConfig}
}

deployMarketSequence({}, 'TxnSimpleMarketV4', '0xAB594600376Ec9fD91F8e885dADF0CE036862dE0', true, 18,
    [])
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })