import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-web3';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-truffle5';
import '@nomiclabs/hardhat-ganache';

import 'hardhat-gas-reporter';

import { config as dotEnvConfig } from 'dotenv';
dotEnvConfig();

import { HardhatUserConfig } from 'hardhat/types';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async () => {
//   const accounts = await ethers.getSigners();
//
//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
//https://api.bscscan.com/api?module=gastracker&action=gasoracle&apikey=YourApiKeyToken
//Ethereum (default)	ETH	https://api.etherscan.io/api?module=proxy&action=eth_gasPrice
//Binance	BNB	https://api.bscscan.com/api?module=proxy&action=eth_gasPrice
//Polygon	MATIC	https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice
//Avalanche	AVAX	https://api.snowtrace.io/api?module=proxy&action=eth_gasPrice
//Heco	HT	https://api.hecoinfo.com/api?module=proxy&action=eth_gasPrice
//Moonriver	MOVR	https://api-moonriver.moonscan.io/api?module=proxy&action=eth_gasPrice
const config: HardhatUserConfig = {
    defaultNetwork: 'hardhat',
    gasReporter: {
        currency: 'USD',
        token:'BNB',
        gasPriceApi:'https://api.bscscan.com/api?module=proxy&action=eth_gasPrice',
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        showTimeSpent:true,
        enabled: true
    },
    paths: {
        sources: './contracts',
        tests: './test',
        artifacts: './artifacts',
        cache: './cache',
    },
    networks: {
        hardhat: {
            hardfork: "istanbul",
            forking: {
                url: `${process.env.ARCHIVE_BSC_MAIN_RPC_URL}`,
                // url: 'http://localhost:8545',
                // blockNumber: 13000000,
                blockNumber: 23806000,
            },
            accounts: [
                // 5 accounts with 10^14 ETH each
                // Addresses:
                //   0x186e446fbd41dD51Ea2213dB2d3ae18B05A05ba8
                //   0x6824c889f6EbBA8Dac4Dd4289746FCFaC772Ea56
                //   0xCFf94465bd20C91C86b0c41e385052e61ed49f37
                //   0xEBAf3e0b7dBB0Eb41d66875Dd64d9F0F314651B3
                //   0xbFe6D5155040803CeB12a73F8f3763C26dd64a92
                {
                    privateKey:
                        '0xf269c6517520b4435128014f9c1e50c1c498374a7f5143f035bfb32153f3adab',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0xca3547a47684862274b476b689f951fad53219fbde79f66c9394e30f1f0b4904',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0x4bad9ef34aa208258e3d5723700f38a7e10a6bca6af78398da61e534be792ea8',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0xffc03a3bd5f36131164ad24616d6cde59a0cfef48235dd8b06529fc0e7d91f7c',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0x380c430a9b8fa9cce5524626d25a942fab0f26801d30bfd41d752be9ba74bd98',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0xabd8696aa229746ab751f21e05228ff237febf28bf96219de1bc0b3147e7e538',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0x03116f89f0c568c8b2db732c1b1cb6c69aa9dbf1f9dbe94c2b1231bd462c8cc2',
                    balance: '100000000000000000000000000000000',
                },
                {
                    privateKey:
                        '0x5118053eb25e1974878c1f47be5e554424d60e52ababad9c15f876eebc9ebd48',
                    balance: '100000000000000000000000000000000',
                },
            ],
            allowUnlimitedContractSize: false,
            blockGasLimit: 40000000,
            gas: 40000000,
            gasPrice: 'auto',
            loggingEnabled: false,
        },
        mainnet: {
            url: `${process.env.GETBLOCK_BSC_MAIN_RPC_URL}`,
            accounts: [`${process.env.PRIVATE_KEY_BSC}`],
        },
        development: {
            url: 'http://127.0.0.1:8545',
            gas: 12400000,
            timeout: 1000000,
        },
    },
    solidity: {
        compilers: [
            {
                version: '0.8.17',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                    viaIR:true
                },
            },
        ],
    },
    mocha: {
        timeout: 500000,
    },
    etherscan: {
        apiKey: `${process.env.BSCSCAN_API_KEY}`,
    },
};

export default config;
