import chainMarkets from "./chain-configs.mjs";

async function initMarket(chain) {
    const chainCfg = chainMarkets[chain]
    if (chainCfg == null) {
        throw 'chain config not found ' + chain
    }
    let roleManagerAddr = chainCfg.roleManager
    let saleMarketAddr = chainCfg.salemarket
    let mintMarketAddr = chainCfg.mintable
    let nftAddrs = chainCfg.nft
    let marketAddr = chainCfg.market
    const RoleManager = await ethers.getContractFactory('TxnHubRoleManagerV0')
    const SaleMarket = await ethers.getContractFactory('TxnSaleMarketV0')
    const MintMarket = await ethers.getContractFactory('TxnMintableMarketV0')
    const TxnHubSimpleGiftCardNFT = await ethers.getContractFactory('TxnHubBasicGiftCardNFTV2')
    const roleManager = await RoleManager.attach(roleManagerAddr)
    const saleMarket = await SaleMarket.attach(saleMarketAddr)
    const mintMarket = await MintMarket.attach(mintMarketAddr)
    for (let nftAddr of nftAddrs){
        const nft = await TxnHubSimpleGiftCardNFT.attach(nftAddr)
        await nft.setAuthorizedContract(mintMarketAddr)
    }
    await roleManager.authorizeToContract(marketAddr, true);
    await saleMarket.authorizeToContract(marketAddr, true);
    return await mintMarket.authorizeToContract(marketAddr, true);
}

initMarket('polygon')
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })