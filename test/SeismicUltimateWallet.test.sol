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
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();

        
        SUint256 transferAmount = SUint256.wrap(0.5 ether);
        bytes memory encryptedSMS = "encrypted message";
        wallet.sendTransaction(SAddress.wrap(user1), transferAmount, encryptedSMS);

        
        uint256 remainingBalance = wallet.getMyBalance();
        assertEq(remainingBalance, depositAmount - 0.5 ether, "Owner balance should decrease");

        
        uint256 user1Balance = wallet.getBalance(SAddress.wrap(user1));
        assertEq(user1Balance, 0, "Non-owner should see user1 balance as 0");
    }

    function testWithdraw() public {
        
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();

        
        SUint256 transferAmount = SUint256.wrap(0.5 ether);
        bytes memory encryptedSMS = "encrypted message";
        wallet.sendTransaction(SAddress.wrap(user1), transferAmount, encryptedSMS);

        
        vm.warp(block.timestamp + 1801);

        
        vm.prank(user1);
        uint256 initialBalance = user1.balance;
        wallet.withdraw(0.5 ether);
        uint256 finalBalance = user1.balance;
        assertEq(finalBalance - initialBalance, 0.5 ether, "User1 should withdraw 0.5 ether");
    }

    function testGetBalanceForNonOwner() public {
        
        uint256 depositAmount = 1 ether;
        vm.deal(owner, depositAmount);
        wallet.deposit{value: depositAmount}();
        
        
        uint256 ownerBalance = wallet.getMyBalance();
        assertEq(ownerBalance, depositAmount, "Owner balance should match deposit");

        
        uint256 user2Balance = wallet.getBalance(SAddress.wrap(user2));
        assertEq(user2Balance, 0, "Non-owner should see user2 balance as 0");
    }
}
