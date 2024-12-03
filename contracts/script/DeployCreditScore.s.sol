// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {CreditScore} from "src/CreditScore.sol";

contract DeployCreditScore is Script {
    function run() public {
        vm.startBroadcast();
        CreditScore scoreKeeper = new CreditScore();
        scoreKeeper.initialize(vm.addr(0x100));
        vm.stopBroadcast();

        console.log("CreditScore deployed at: ", address(scoreKeeper));
    }
}
