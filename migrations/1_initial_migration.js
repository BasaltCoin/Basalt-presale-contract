const BasaltTokenSale = artifacts.require("BasaltTokenSale");

module.exports = async (deployer, network) => {
  if (network == "bscmain") {
    try {
      await deployer.deploy(BasaltTokenSale);
    } catch (err) {
      console.log("ERROR:", err);
    }
  }
};
