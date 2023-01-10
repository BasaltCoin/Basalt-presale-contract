const BasaltTokenSale = artifacts.require("BasaltTokenSale");
const BasaltToken = artifacts.require("BasaltToken");

module.exports = async (deployer, network) => {
  if (network == "bscmain") {
    const BUSD_ADDRESS="0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
    try {
      const paymentToken={
        tokenAddress:BUSD_ADDRESS,
        price:web3.utils.toWei("2", "ether"),
    }
      await deployer.deploy(BasaltToken);
      await deployer.deploy(BasaltTokenSale,BasaltToken.address,paymentToken);
    } catch (err) {
      console.log("ERROR:", err);
    }
  }else if(network == "bsctest") {
    try {
      const BUSD_ADDRESS="0x90a2182EBb0F5D4E171CbD0C22fb8682ec923cd4";
      const paymentToken={
        tokenAddress:BUSD_ADDRESS,
        price:web3.utils.toWei("1", "ether"),
      }
      await deployer.deploy(BasaltToken,web3.utils.toWei("1000000", "ether"));
      await deployer.deploy(BasaltTokenSale,BasaltToken.address,paymentToken);
    } catch (err) {
      console.log("ERROR:", err);
    }
  }
};
