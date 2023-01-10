const Web3 = require('web3');
const dot = require('dotenv');
dot.config();
const { ARCHIVE_BSC_MAIN_RPC_URL } = process.env;

const MAX_HISTORY = 120;
const ADDRESS = '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82';

const web3 = new Web3(ARCHIVE_BSC_MAIN_RPC_URL);

const run = async () => {
  const number = await web3.eth.getBlockNumber();
  const fromBlock = number - MAX_HISTORY;

  // topic: Transfer(address,address,uint256)
  const topics = [
    '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
  ];

  const logs = await web3.eth.getPastLogs({
    fromBlock,
    address: ADDRESS,
    topics,
  });

  const max = logs.reduce((a, b) =>
    web3.utils.toBN(a.data).gt(web3.utils.toBN(b.data)) ? a : b
  );
  const destination = max.topics[2].slice(-40);
  console.log(`0x${destination}`);
};

run();