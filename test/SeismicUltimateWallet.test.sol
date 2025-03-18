// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/SeismicUltimateWallet.sol";

contract SeismicUltimateWalletTest is Test {
    SeismicUltimateWallet wallet;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x123);
        user2 = address(0x456);
        wallet = new SeismicUltimateWallet();
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();
        uint256 balance = wallet.getMyBalance();
        assertEq(balance, depositAmount, "Deposit amount should match balance");
    }

    function testSendTransaction() public {
        // Owner deposits 1 ether
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();

        // Owner sends 0.5 ether to user1 with an encrypted SMS
        SUint256 transferAmount = SUint256.wrap(0.5 ether);
        bytes memory encryptedSMS = "encrypted message";
        wallet.sendTransaction(SAddress.wrap(user1), transferAmount, encryptedSMS);

        // Проверка: баланс владельца уменьшился на 0.5 ether
        uint256 remainingBalance = wallet.getMyBalance();
        assertEq(remainingBalance, depositAmount - 0.5 ether, "Owner balance should decrease");

        // При запросе баланса для user1 извне должен возвращаться 0
        uint256 user1Balance = wallet.getBalance(SAddress.wrap(user1));
        assertEq(user1Balance, 0, "Non-owner should see user1 balance as 0");
    }

    function testWithdraw() public {
        // Owner депонирует 1 ether
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();

        // Owner отправляет 0.5 ether user1
        SUint256 transferAmount = SUint256.wrap(0.5 ether);
        bytes memory encryptedSMS = "encrypted message";
        wallet.sendTransaction(SAddress.wrap(user1), transferAmount, encryptedSMS);

        // Перематываем время вперед более чем на 1800 секунд (30 минут)
        vm.warp(block.timestamp + 1801);

        // Имперсонируем user1 для вывода заблокированных средств
        vm.prank(user1);
        uint256 initialBalance = user1.balance;
        wallet.withdraw(0.5 ether);
        uint256 finalBalance = user1.balance;
        assertEq(finalBalance - initialBalance, 0.5 ether, "User1 should withdraw 0.5 ether");
    }

    function testGetBalanceForNonOwner() public {
        // Owner депонирует 1 ether
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();
        
        // Владелец видит свой баланс
        uint256 ownerBalance = wallet.getMyBalance();
        assertEq(ownerBalance, depositAmount, "Owner balance should match deposit");

        // При запросе баланса другого аккаунта (user2) должен возвращаться 0
        uint256 user2Balance = wallet.getBalance(SAddress.wrap(user2));
        assertEq(user2Balance, 0, "Non-owner should see user2 balance as 0");
    }
}
