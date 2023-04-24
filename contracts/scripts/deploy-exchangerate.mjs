async function deployExchange(currency, digits, value) {
    const Aggregator = await ethers.getContractFactory('CustomizedAggregatorV3Contract')
    const aggregator = await Aggregator.deploy(currency, digits, value)
    await aggregator.deployed()
    return aggregator
}

deployExchange('USDC',
    8,
    100100000)
    .then((obj) => {
        console.log(obj)
        process.exit(0)
    })
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })