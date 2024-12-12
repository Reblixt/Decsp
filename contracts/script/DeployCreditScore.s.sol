// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {CreditScore} from "src/CreditScore.sol";

contract DeployCreditScore is Script {
    address owner = msg.sender;

    function run() public {
        vm.startBroadcast();
        // CreditScore scoreKeeper = new CreditScore();
        // if (block.chainid == 31337) {
        //     scoreKeeper.initialize(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        // } else {
        //     scoreKeeper.initialize(owner);
        // }
        blockTimeTest test = new blockTimeTest();
        uint blockTime = test.getBlockTime();
        vm.stopBroadcast();
        console.log("Block Time: ", blockTime);
        // console.log("CreditScore deployed at: ", address(scoreKeeper));
    }
}

contract blockTimeTest {
    function getBlockTime() public view returns (uint) {
        return block.timestamp;
    }
}
