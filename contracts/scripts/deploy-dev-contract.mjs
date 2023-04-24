async function deploy() {
    const TestContract = await ethers.getContractFactory('ContractBitMathTest')
    const testContract = await TestContract.deploy()
    await testContract.deployed()
    const trxHash = testContract.deployTransaction.hash
    console.log('dev contract address = ' + testContract.address + ' , txhash = ' + trxHash)
}
async function testBitMath(){
    const TestContract = await ethers.getContractFactory('ContractBitMathTest')
    const testContract = await TestContract.attach('0x5611BAe9e9BC3D475d04e7a2ff20BECB56655dc1')
    return await testContract.maskPrice('1','199960')
}
testBitMath().then((res)=>console.log(res))