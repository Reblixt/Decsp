// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CreditScore} from "src/CreditScore.sol";

contract TestCreditScore is Test {
    CreditScore deployer;

    function setUp() public {
        deployer = new CreditScore();
    }
}
