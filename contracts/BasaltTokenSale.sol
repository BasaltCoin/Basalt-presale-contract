// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasaltTokenSale is Ownable {
    using SafeERC20 for IERC20;

    struct PaymentToken {
        address tokenAddress;
        uint256 price; //price of one basaltToken
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

    uint256 public constant PURCHASE_PERIOD = 30 days;
    uint256 public constant STAGE_DURATION = 30 days;
    uint256 public constant NUMBER_OF_STAGES = 28;
    uint256 public constant REFERRER_FEE_BP = 250; //2.5%
    uint256 public constant BP = 10000;
    uint256 public constant MINIMUM_PURCHASED_AMOUNT = 1e18;
    address public immutable basaltToken;
    uint256 public totalLockedAmount;
    uint256 public immutable firstUnlockAmtBP;

    PaymentToken[] public paymentTokens;
    mapping(address => bool) public isPaymentToken;
    mapping(address => UserInfo) public userInfo;
    mapping(address => address[]) public referrals;

    modifier correctID(uint256 _id) {
        require(_id < paymentTokens.length, "bad token id");
        _;
    }

    constructor(
        address _basaltToken,
        PaymentToken[] memory _paymentTokens,
        uint256 _firstUnlockAmtBP
    ) {
        basaltToken = _basaltToken;
        firstUnlockAmtBP = _firstUnlockAmtBP;
        for (uint256 i; i < _paymentTokens.length; i++) {
            paymentTokens.push(_paymentTokens[i]);
            isPaymentToken[_paymentTokens[i].tokenAddress] = true;
        }
    }

    function addPaymentToken(
        PaymentToken calldata _paymentToken
    ) external onlyOwner {
        require(
            isPaymentToken[_paymentToken.tokenAddress] == false,
            "token already exist"
        );
        isPaymentToken[_paymentToken.tokenAddress] = true;
        paymentTokens.push(_paymentToken);
    }

    function removePaymentToken(
        uint256 _paymentTokenID
    ) external onlyOwner correctID(_paymentTokenID) {
        address tokenAddress = paymentTokens[_paymentTokenID].tokenAddress;
        paymentTokens[_paymentTokenID] = paymentTokens[
            paymentTokens.length - 1
        ];
        paymentTokens.pop();
        isPaymentToken[tokenAddress] = false;
    }

    function changePaymentToken(
        uint256 _paymentTokenID,
        uint256 _price
    ) external onlyOwner correctID(_paymentTokenID) {
        paymentTokens[_paymentTokenID].price = _price;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        if (_token == basaltToken) {
            require(
                _amount <=
                    IERC20(basaltToken).balanceOf(address(this)) -
                        totalLockedAmount,
                "_amount exceeds free balance"
            );
        }
        _pay(_token, address(this), _to, _amount);
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
            _pay(basaltToken, address(this), _to, unlockingAmount);
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
                IERC20(basaltToken).balanceOf(address(this)) -
                    totalLockedAmount,
            "_basaltTokenAmount exceeds free balance"
        );

        UserInfo storage user = userInfo[msg.sender];
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
        totalLockedAmount += _basaltTokenAmount;

        uint256 payableAmount = (_basaltTokenAmount * paymentInfo.price) /
            10 ** 18;

        uint256 referrerFee = (payableAmount * REFERRER_FEE_BP) / BP;
        payableAmount -= referrerFee;
        _pay(paymentInfo.tokenAddress, msg.sender, user.referrer, referrerFee);
        _pay(paymentInfo.tokenAddress, msg.sender, owner(), payableAmount);
    }

    function withdrawUnlockedBasaltTokens() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 lockedAmount = user.totalPurchasedAmount -
            user.totalWithdrawnAmount;
        require(lockedAmount > 0, "you don't have tokens");
        require(
            user.unlockStartTime < block.timestamp,
            "unlock has not started yet"
        );
        uint256 allowedAmount = getAllowedAmount(msg.sender);
        require(allowedAmount > 0, "no tokens available for withdrawal");
        user.totalWithdrawnAmount += allowedAmount;
        totalLockedAmount -= allowedAmount;
        _pay(basaltToken, address(this), msg.sender, allowedAmount);
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
    ) public view returns (uint256 allowedAmount) {
        UserInfo memory user = userInfo[_user];
        uint256 lockedAmount = user.totalPurchasedAmount -
            user.totalWithdrawnAmount;
        if (lockedAmount > 0 && user.unlockStartTime < block.timestamp) {
            uint256 currentStage = (block.timestamp - user.unlockStartTime) /
                STAGE_DURATION;
            if (currentStage > NUMBER_OF_STAGES) {
                currentStage = NUMBER_OF_STAGES;
            }
            uint256 firstUnlockAmt = (user.totalPurchasedAmount *
                firstUnlockAmtBP) / BP;
            allowedAmount =
                firstUnlockAmt +
                ((user.totalPurchasedAmount - firstUnlockAmt) * currentStage) /
                NUMBER_OF_STAGES;
            allowedAmount = allowedAmount > user.totalWithdrawnAmount
                ? allowedAmount - user.totalWithdrawnAmount
                : 0;
        }
    }

    function _pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) private {
        if (value > 0) {
            if (payer == address(this)) {
                IERC20(token).safeTransfer(recipient, value);
            } else {
                IERC20(token).safeTransferFrom(payer, recipient, value);
            }
        }
    }
}
