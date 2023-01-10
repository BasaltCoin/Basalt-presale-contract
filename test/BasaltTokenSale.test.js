const { expectRevert, time,BN,ether} = require('@openzeppelin/test-helpers');
const { ethers, network } = require('hardhat');
const BasaltToken = artifacts.require('BasaltToken');
const IBEP20 = artifacts.require('IBEP20');
const IERC20= artifacts.require('IERC20');
const BasaltTokenSale = artifacts.require('BasaltTokenSale');
const ForceSend = artifacts.require('ForceSend');
const BUSD_DONOR_ADDRESS='0x9ba8966b706c905e594acbb946ad5e29509f45eb';
const BUSD_ADDRESS="0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
const USDT_ADDRESS="0x55d398326f99059fF775485246999027B3197955";
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

contract("BasaltTokenSale",  ([owner, referrer, user,user1]) => {


    before(async () => {

        const forceSend = await ForceSend.new();
        await forceSend.go(BUSD_DONOR_ADDRESS, { value: web3.utils.toWei("1", "ether") });
        this.BUSD = await IBEP20.at(BUSD_ADDRESS);
  
        await network.provider.request({
            method: 'hardhat_impersonateAccount',
            params: [BUSD_DONOR_ADDRESS],
        });
  
        await this.BUSD.transfer(user,web3.utils.toWei("10000", "ether"),{ from: BUSD_DONOR_ADDRESS });
        await this.BUSD.transfer(user1,web3.utils.toWei("10000", "ether"),{ from: BUSD_DONOR_ADDRESS });
        
        this.basaltToken =await BasaltToken.new(web3.utils.toWei("100000", "ether"));
        const paymentToken={
            tokenAddress:BUSD_ADDRESS,
            price:web3.utils.toWei("2", "ether"),
        }
        this.basaltTokenSale=await BasaltTokenSale.new(this.basaltToken.address,paymentToken, { from: owner });
        
        await this.BUSD.approve(this.basaltTokenSale.address, web3.utils.toWei("10000", "ether"), { from: user });
        await this.BUSD.approve(this.basaltTokenSale.address, web3.utils.toWei("10000", "ether"), { from: user1 });
        
        await this.basaltToken.transfer(this.basaltTokenSale.address,web3.utils.toWei("100000", "ether"), { from: owner });
  
    });

    it('addPaymentToken', async () => {
        const paymentToken={
            tokenAddress:USDT_ADDRESS,
            price:web3.utils.toWei("2", "ether"),
        }
        await this.basaltTokenSale.addPaymentToken(paymentToken, { from: owner });
    });

    it('changePaymentToken', async () => {
        await this.basaltTokenSale.changePaymentToken(1,web3.utils.toWei("3", "ether"), { from: owner });
    });

    it('removePaymentToken', async () => {
        await this.basaltTokenSale.removePaymentToken(1, { from: owner });
    });

    it('buyBasaltTokens', async () => {
        await this.basaltTokenSale.buyBasaltTokens(0,web3.utils.toWei("10000", "ether"),referrer, { from: user });
        await this.basaltTokenSale.buyBasaltTokens(0,web3.utils.toWei("5000", "ether"),referrer, { from: user1 });
        await this.basaltTokenSale.buyBasaltTokens(0,web3.utils.toWei("5000", "ether"),ZERO_ADDRESS, { from: user1 });

        assert.equal(web3.utils.fromWei(await this.BUSD.balanceOf(user).valueOf()), "5000");
        assert.equal(web3.utils.fromWei(await this.BUSD.balanceOf(user1).valueOf()), "5000");
        assert.equal(web3.utils.fromWei(await this.BUSD.balanceOf(referrer).valueOf()), "250");// 2.5%
        assert.equal(web3.utils.fromWei(await this.BUSD.balanceOf(owner).valueOf()), "9750");// 97.5%
    });

    it('unlockAcceleration', async () => {
        await this.basaltTokenSale.unlockAcceleration(user,100,{ from: owner });//1%
        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(user).valueOf()), "100");
    });

    it('withdrawUnlockedBasaltTokens', async () => {
        const PURCHASE_PERIOD = await this.basaltTokenSale.PURCHASE_PERIOD();
        const STAGE_DURATION = await this.basaltTokenSale.STAGE_DURATION();
        await expectRevert(
            this.basaltTokenSale.withdrawUnlockedBasaltTokens({ from: user }), 
            'unlock has not started yet',
        );
        await time.increase(PURCHASE_PERIOD);
        assert.equal(await this.basaltTokenSale.getAllowedAmount(user), "0");
        assert.equal(await this.basaltTokenSale.getAllowedAmount(user1), "0");
        await time.increase(STAGE_DURATION);// 0
        assert.equal(web3.utils.fromWei(await this.basaltTokenSale.getAllowedAmount(user)), "108.333333333333333333");//10000 / 48 -100
        assert.equal(web3.utils.fromWei(await this.basaltTokenSale.getAllowedAmount(user1)), "208.333333333333333333");//10000 / 48

        await this.basaltTokenSale.withdrawUnlockedBasaltTokens({ from: user });
        await this.basaltTokenSale.withdrawUnlockedBasaltTokens({ from: user1 });

        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(user).valueOf()), "208.333333333333333333");
        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(user1).valueOf()), "208.333333333333333333");

        await time.increase(STAGE_DURATION);// 1
        assert.equal(web3.utils.fromWei(await this.basaltTokenSale.getAllowedAmount(user)), "208.333333333333333333");
        assert.equal(web3.utils.fromWei(await this.basaltTokenSale.getAllowedAmount(user1)), "208.333333333333333333");
        await this.basaltTokenSale.withdrawUnlockedBasaltTokens({ from: user });
        await this.basaltTokenSale.withdrawUnlockedBasaltTokens({ from: user1 });
        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(user).valueOf()), "416.666666666666666666");
        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(user1).valueOf()), "416.666666666666666666");

    });

    it('inCaseTokensGetStuck', async () => {
        assert.equal(await this.basaltToken.balanceOf(owner).valueOf(), "0");
        await expectRevert(
            this.basaltTokenSale.inCaseTokensGetStuck(this.basaltToken.address,web3.utils.toWei("80001", "ether"),owner,{ from: owner }), 
            "_amount exceeds free balance"
        );
        await this.basaltTokenSale.inCaseTokensGetStuck(this.basaltToken.address,web3.utils.toWei("80000", "ether"),owner,{ from: owner });
        assert.equal(web3.utils.fromWei(await this.basaltToken.balanceOf(owner).valueOf()), "80000");
    });

    it('getReferralsInfo', async () => {
        const Info = await this.basaltTokenSale.getReferralsInfo(referrer);
        const totalPurchasedAmount=Info[0];
        const referralsInfo=Info[1];
        assert.equal(web3.utils.fromWei(totalPurchasedAmount), "20000");
        assert.equal(referralsInfo[0].user, user);
        assert.equal(web3.utils.fromWei(referralsInfo[0].purchasedAmount), "10000");
        assert.equal(referralsInfo[1].user, user1);
        assert.equal(web3.utils.fromWei(referralsInfo[1].purchasedAmount), "10000"); 
    });

});