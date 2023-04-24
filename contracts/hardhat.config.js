/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-ethers")
require('@openzeppelin/hardhat-upgrades')
require('dotenv').config()
const {PRIVATE_KEY} = process.env || '1111'
module.exports = {
    defaultNetwork: "PolygonMumbai",
    networks: {
        hardhat: {},
        PolygonMumbai: {
            url: 'https://endpoints.omniatech.io/v1/matic/mumbai/public',
            accounts: [PRIVATE_KEY]
        },
        Polygon: {
            url: 'https://polygon.llamarpc.com',
            accounts: [PRIVATE_KEY]
        },
        Goerli: {
            url: 'https://goerli.infura.io/v3/5a8848f780464d559b7fc5bf7c1824dd',
            accounts: [PRIVATE_KEY]
        },
        Eth: {
            url: 'https://endpoints.omniatech.io/v1/eth/mainnet/public',
            accounts: [PRIVATE_KEY]
        },
        PlatOnTest: {
            url: 'https://devnet2openapi.platon.network/rpc',
            accounts: [PRIVATE_KEY]
        },
        PlatOn: {
            url: 'https://openapi2.platon.network/rpc',
            accounts: [PRIVATE_KEY]
        }
    },
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
};
