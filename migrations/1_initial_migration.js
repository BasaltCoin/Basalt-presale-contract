const BasaltTokenSale = artifacts.require("BasaltTokenSale");
const BasaltToken = artifacts.require("BasaltToken");

module.exports = async (deployer, network) => {
  if (network == "bscmain") {
    const USDT = "0x55d398326f99059fF775485246999027B3197955";
    const USDC = "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d";
    const BasaltTokenAddress = "0xbba4d3CBf9B3c71bb51491DeE3a9D6abd34f1f2D";
    //const PRE_MINT_AMOUNT = web3.utils.toWei("50000000", "ether");//ether for decimals:18(BUSD)
    const firstUnlockAmtBP = "1500";//15%
    try {
      const paymentTokens = [
        {
          tokenAddress: USDT,
          price: web3.utils.toWei("0.07", "ether"),
        },
        {
          tokenAddress: USDC,
          price: web3.utils.toWei("0.07", "ether"),
        }
      ];

      //await deployer.deploy(BasaltToken, PRE_MINT_AMOUNT);
      await deployer.deploy(BasaltTokenSale, BasaltTokenAddress, paymentTokens, firstUnlockAmtBP);// 0x7A28BA519e9dcDC4f5FbC4F09911ebd15dEa8D6C
    } catch (err) {
      console.log("ERROR:", err);
    }
  } else if (network == "bsctest") {
    try {
      const BUSD_ADDRESS = "0x90a2182EBb0F5D4E171CbD0C22fb8682ec923cd4";
      const PRE_MINT_AMOUNT = web3.utils.toWei("1000000", "ether");
      const paymentToken = {
        tokenAddress: BUSD_ADDRESS,
        price: web3.utils.toWei("1", "ether"),
      }
      await deployer.deploy(BasaltToken, PRE_MINT_AMOUNT);
      await deployer.deploy(BasaltTokenSale, BasaltToken.address, paymentToken);
    } catch (err) {
      console.log("ERROR:", err);
    }
  }
};
