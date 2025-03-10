// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {CreditScore} from "src/CreditScore.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployCreditScore is Script {
    // address owner = msg.sender;
    // address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address owner = 0x68B0fcF47729688097709d98Fa4DEc4643A96959;
    uint256 ownerPrivateKey = vm.envUint("PRIVATE_OWNER_KEY");

    uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
    //uint256 userPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    address userAddress = 0xED4C2Ffb6AEBa7E5D1c4b0346f3b669f28e502e1;

    function run() public {
        vm.startBroadcast(ownerPrivateKey);
        // CreditScore scoreKeeper = new CreditScore();
        // scoreKeeper.initialize(owner);
        address scoreKeeper = Upgrades.deployUUPSProxy(
            "CreditScore.sol",
            abi.encodeCall(CreditScore.initialize, (owner))
        );

        vm.stopBroadcast();

        callAddLender(address(scoreKeeper), owner);

        approveLender(address(scoreKeeper), owner);

        uint256 id = newClientAndCreatePaymentPlan(
            address(scoreKeeper),
            userAddress
        );

        approvePaymentPlan(address(scoreKeeper), id);

        Pay(address(scoreKeeper), id);

        console.log("CreditScore deployed at: ", address(scoreKeeper));
    }

    function callAddLender(address _scoreKeeper, address _lender) public {
        vm.startBroadcast(ownerPrivateKey);
        CreditScore(_scoreKeeper).addLender(_lender);
        vm.stopBroadcast();
    }

    function approveLender(address _scoreKeeper, address _lender) public {
        vm.startBroadcast(userPrivateKey);
        CreditScore(_scoreKeeper).approveLender(_lender);
        vm.stopBroadcast();
    }

    function newClientAndCreatePaymentPlan(
        address _scoreKeeper,
        address _user
    ) public returns (uint256) {
        vm.startBroadcast(ownerPrivateKey);
        CreditScore(_scoreKeeper).newClient(_user);
        uint256 id = CreditScore(_scoreKeeper).createPaymentPlan(
            _user,
            1000,
            20 days,
            2,
            6
        );
        vm.stopBroadcast();
        return id;
    }

    function approvePaymentPlan(address _scoreKeeper, uint256 id) public {
        vm.startBroadcast(userPrivateKey);
        CreditScore(_scoreKeeper).approveNewPaymentPlan(id);
        vm.stopBroadcast();
    }

    function Pay(address _scoreKeeper, uint256 id) public {
        vm.startBroadcast(ownerPrivateKey);
        CreditScore(_scoreKeeper).payment(500, id);
        vm.stopBroadcast();
    }
}
