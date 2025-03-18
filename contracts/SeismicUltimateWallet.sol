// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

type SUint256 is uint256;
type SAddress is address;

contract SeismicUltimateWallet {
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "Reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    mapping(SAddress => SUint256) private balances;
    mapping(SAddress => LockedFunds[]) private lockedBalances;

    struct LockedFunds {
        SUint256 amount;
        uint256 unlockTime;
    }

    event TransactionConfirmed(
        SAddress indexed sender,
        SAddress indexed recipient,
        SUint256 amount,
        uint256 timestamp,
        bytes32 transactionId
    );

    function deposit() external payable nonReentrant {
        SAddress sender = SAddress.wrap(msg.sender);
        SUint256 currentBalance = balances[sender];
        SUint256 depositAmount = SUint256.wrap(msg.value);
        balances[sender] = SUint256.wrap(SUint256.unwrap(currentBalance) + SUint256.unwrap(depositAmount));
    }

    function sendTransaction(SAddress recipient, SUint256 amount, bytes calldata encryptedSMS) external nonReentrant {
        SAddress sender = SAddress.wrap(msg.sender);
        uint256 senderBalance = SUint256.unwrap(balances[sender]);
        require(senderBalance >= SUint256.unwrap(amount), "Insufficient funds");
        balances[sender] = SUint256.wrap(senderBalance - SUint256.unwrap(amount));
        LockedFunds memory lockEntry = LockedFunds({
            amount: amount,
            unlockTime: block.timestamp + 1800
        });
        lockedBalances[recipient].push(lockEntry);
        bytes32 txId = keccak256(
            abi.encodePacked(msg.sender, SAddress.unwrap(recipient), SUint256.unwrap(amount), block.timestamp, encryptedSMS)
        );
        emit TransactionConfirmed(sender, recipient, amount, block.timestamp, txId);
    }

    function withdraw(uint256 amountToWithdraw) external nonReentrant {
        SAddress sender = SAddress.wrap(msg.sender);
        uint256 availableBalance = SUint256.unwrap(balances[sender]);
        LockedFunds[] storage locks = lockedBalances[sender];
        uint256 unlockedAmount = 0;
        for (uint i = 0; i < locks.length; ) {
            if (block.timestamp >= locks[i].unlockTime) {
                unlockedAmount += SUint256.unwrap(locks[i].amount);
                locks[i] = locks[locks.length - 1];
                locks.pop();
            } else {
                i++;
            }
        }
        availableBalance += unlockedAmount;
        require(availableBalance >= amountToWithdraw, "Insufficient unlocked funds");
        balances[sender] = SUint256.wrap(availableBalance - amountToWithdraw);
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function getMyBalance() external view returns (uint256) {
        SAddress sender = SAddress.wrap(msg.sender);
        return SUint256.unwrap(balances[sender]);
    }

    function getBalance(SAddress account) external view returns (uint256) {
        if (SAddress.unwrap(account) == msg.sender) {
            return SUint256.unwrap(balances[account]);
        }
        return 0;
    }
}
