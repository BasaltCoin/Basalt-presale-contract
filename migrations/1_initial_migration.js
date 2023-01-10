const BasaltTokenSale = artifacts.require("BasaltTokenSale");
const BasaltToken = artifacts.require("BasaltToken");

module.exports = async (deployer, network) => {
  if (network == "bscmain") {
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
  }
};
