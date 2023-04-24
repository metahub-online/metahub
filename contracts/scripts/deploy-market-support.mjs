
const contractNames = {
    'rolemanager': 'TxnHubRoleManagerV0',
    'mintable': 'TxnMintableMarketV0',
    'sale': 'TxnSaleMarketV0'
}
async function deploySupports(contractId) {
    const contractName = contractNames[contractId]
    if (contractName==null){
        throw 'not found contract:'+contractId
    }
    const SupportContract = await ethers.getContractFactory(contractName)
    const contract = await upgrades.deployProxy(SupportContract, [], {initializer: 'initialize'})
    await contract.deployed()
    return contract
}

//Contract sequence:
//- TxnHubRoleManagerV0
//- TxnMintableMarketV0
//- TxnSaleMarketV0

deploySupports('sale')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })