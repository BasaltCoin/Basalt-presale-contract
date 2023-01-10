// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BasaltTokenSale is Ownable {
    using SafeERC20 for IERC20;

    struct PaymentToken {
        address tokenAddress;
        uint256 price; // price in basaltToken of one paymentToken
    }

    struct ReferralInfo {
        address user;
        uint256 purchasedAmount;
    }

    struct UserInfo {
        address referrer;
        uint256 totalPurchasedAmount;
        uint256 totalWithdrawnAmount;
        uint256 unlockStartTime;
    }

    uint256 public constant PURCHASE_PERIOD = 360 days;
    uint256 public constant STAGE_DURATION = 30 days;
    uint256 public constant NUMBER_OF_STAGES = 48;
    uint256 public constant REFERRER_FEE_BP = 250; //2.5%
    uint256 public constant BP = 10000;
    uint256 public constant MINIMUM_PURCHASED_AMOUNT = 1e18;
    IERC20 public immutable basaltToken;
    uint256 public totalLockedAmount;

    PaymentToken[] public paymentTokens;
    mapping(address => UserInfo) public userInfo;
    mapping(address => address[]) public referrals;

    modifier correctID(uint256 _id) {
        require(_id < paymentTokens.length, "bad token id");
        _;
    }

    constructor(IERC20 _basaltToken, PaymentToken memory _paymentToken) {
        basaltToken = _basaltToken;
        paymentTokens.push(_paymentToken);
    }

    function addPaymentToken(
        PaymentToken calldata _paymentToken
    ) external onlyOwner {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            require(
                paymentTokens[i].tokenAddress != _paymentToken.tokenAddress,
                "token already exist"
            );
        }
        paymentTokens.push(_paymentToken);
    }

    function removePaymentToken(
        uint256 _paymentTokenID
    ) external onlyOwner correctID(_paymentTokenID) {
        paymentTokens[_paymentTokenID] = paymentTokens[
            paymentTokens.length - 1
        ];
        paymentTokens.pop();
    }

    function changePaymentToken(
        uint256 _paymentTokenID,
        uint256 _price
    ) external onlyOwner correctID(_paymentTokenID) {
        paymentTokens[_paymentTokenID].price = _price;
    }

    function inCaseTokensGetStuck(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        if (_token == basaltToken) {
            require(
                _amount <=
                    basaltToken.balanceOf(address(this)) - totalLockedAmount,
                "_amount exceeds free balance"
            );
        }
        _token.safeTransfer(_to, _amount);
    }

    function unlockAcceleration(
        address _to,
        uint256 _unlockBP
    ) external onlyOwner {
        require(_unlockBP <= BP, "incorrect _unlockBP");
        UserInfo storage user = userInfo[_to];
        require(user.referrer != address(0), "user {_to} not found");
        uint256 unlockingAmount = ((user.totalPurchasedAmount -
            user.totalWithdrawnAmount) * _unlockBP) / BP;

        if (unlockingAmount > 0) {
            user.totalWithdrawnAmount += unlockingAmount;
            totalLockedAmount -= unlockingAmount;
            basaltToken.safeTransfer(_to, unlockingAmount);
        }
    }

    function buyBasaltTokens(
        uint256 _paymentTokenID,
        uint256 _basaltTokenAmount,
        address _referrer
    ) external correctID(_paymentTokenID) {
        require(
            _basaltTokenAmount > MINIMUM_PURCHASED_AMOUNT,
            "_basaltTokenAmount is too small"
        );
        require(
            _basaltTokenAmount <=
                basaltToken.balanceOf(address(this)) - totalLockedAmount,
            "_basaltTokenAmount exceeds free balance"
        );

        UserInfo memory user = userInfo[msg.sender];
        PaymentToken memory paymentInfo = paymentTokens[_paymentTokenID];

        if (user.referrer == address(0)) {
            require(
                _referrer != address(0),
                "_referrer cannot be a zero address"
            );
            referrals[_referrer].push(msg.sender);
            user.referrer = _referrer;
            user.unlockStartTime = block.timestamp + PURCHASE_PERIOD;
        } else {
            require(
                user.unlockStartTime > block.timestamp,
                "the purchase period has ended for this user"
            );
        }

        user.totalPurchasedAmount += _basaltTokenAmount;

        uint256 payableAmount = (_basaltTokenAmount *
            10 ** IERC20Metadata(paymentInfo.tokenAddress).decimals()) /
            paymentInfo.price;
        uint256 referrerFee = (payableAmount * REFERRER_FEE_BP) / BP;
        if (referrerFee > 0) {
            IERC20(paymentInfo.tokenAddress).safeTransferFrom(
                msg.sender,
                _referrer,
                referrerFee
            );
        }

        IERC20(paymentInfo.tokenAddress).safeTransferFrom(
            msg.sender,
            owner(),
            payableAmount - referrerFee
        );
        totalLockedAmount += _basaltTokenAmount;
        userInfo[msg.sender] = user;
    }

    function withdrawUnlockedBasaltTokens() external {
        UserInfo memory user = userInfo[msg.sender];
        uint256 lockedAmount = user.totalPurchasedAmount -
            user.totalWithdrawnAmount;
        require(lockedAmount > 0, "you don't have tokens");
        require(
            user.unlockStartTime < block.timestamp,
            "unlock has not started yet"
        );
        uint256 currentStage = (block.timestamp - user.unlockStartTime) /
            STAGE_DURATION;
        if (currentStage > NUMBER_OF_STAGES) {
            currentStage = NUMBER_OF_STAGES;
        }
        uint256 allowedAmount = (user.totalPurchasedAmount * currentStage) /
            NUMBER_OF_STAGES;
        allowedAmount = allowedAmount > user.totalWithdrawnAmount
            ? allowedAmount - user.totalWithdrawnAmount
            : 0;
        if (allowedAmount > 0) {
            user.totalWithdrawnAmount += allowedAmount;
            userInfo[msg.sender] = user;
            totalLockedAmount -= allowedAmount;
            basaltToken.safeTransfer(msg.sender, allowedAmount);
        }
    }

    function getReferralsInfo(
        address referrer
    ) external view returns (uint256, ReferralInfo[] memory) {
        address[] memory allReferrals = referrals[referrer];
        ReferralInfo[] memory referralsInfo = new ReferralInfo[](
            allReferrals.length
        );
        uint256 totalPurchasedAmount;
        for (uint256 i = 0; i < allReferrals.length; i++) {
            address user = allReferrals[i];
            uint256 userPurchasedAmount = userInfo[user].totalPurchasedAmount;
            referralsInfo[i] = ReferralInfo(user, userPurchasedAmount);
            totalPurchasedAmount += userPurchasedAmount;
        }
        return (totalPurchasedAmount, referralsInfo);
    }

    function getAllowedAmount(
        address _user
    ) external view returns (uint256 allowedAmount) {
        UserInfo memory user = userInfo[_user];
        if (user.unlockStartTime < block.timestamp) {
            uint256 currentStage = (block.timestamp - user.unlockStartTime) /
                STAGE_DURATION;
            if (currentStage > NUMBER_OF_STAGES) {
                currentStage = NUMBER_OF_STAGES;
            }
            allowedAmount =
                (user.totalPurchasedAmount * currentStage) /
                NUMBER_OF_STAGES;
            allowedAmount = allowedAmount > user.totalWithdrawnAmount
                ? allowedAmount - user.totalWithdrawnAmount
                : 0;
        }
    }
}
