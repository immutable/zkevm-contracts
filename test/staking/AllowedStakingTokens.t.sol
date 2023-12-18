// Copyright (c) Immutable Pty Ltd
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./AllowedStakingTokensImpl.sol";

contract AllowedStakingTokensTest is Test {
    AllowedStakingTokensImpl public staker;


    function setUp() public {
        staker = new AllowedStakingTokensImpl();
    }

    // Check the add, remove, and get tokens; for just one token at a time.
    function testAddRemoveGetTokensSingular() public {
        address tok1 = address(1);
        address tok2 = address(2);

        address[] memory toks1 = new address[](1);
        toks1[0] = tok1;
        staker.addAllowedStakingTokens(toks1);
        address[] memory toks1Fetched = staker.getAllowedStakingTokens();
        require(toks1Fetched.length == 1, "Toks1Fetched: Incorrect length");
        require(toks1Fetched[0] == tok1, "Toks1Fetched: Incorrect value");

        address[] memory toks2 = new address[](1);
        toks2[0] = tok2;
        staker.addAllowedStakingTokens(toks2);
        address[] memory toks2Fetched = staker.getAllowedStakingTokens();
        require(toks2Fetched.length == 2);
        require(toks2Fetched[0] == tok1);
        require(toks2Fetched[1] == tok2);

        staker.removeAllowedStakingTokens(toks1);
        address[] memory toks3Fetched = staker.getAllowedStakingTokens();
        require(toks3Fetched.length == 1);
        require(toks3Fetched[0] == tok2);

        staker.addAllowedStakingTokens(toks1);
        address[] memory toks4Fetched = staker.getAllowedStakingTokens();
        require(toks4Fetched.length == 2);
        require(toks4Fetched[0] == tok2);
        require(toks4Fetched[1] == tok1);
    }

    // Check the add, remove, and get tokens; multiple tokens at a time.
    function testAddRemoveGetTokensMultiple() public {
        address tok1 = address(1);
        address tok2 = address(2);
        address tok3 = address(3);

        address[] memory toks1 = new address[](3);
        toks1[0] = tok1;
        toks1[1] = tok2;
        toks1[2] = tok3;
        staker.addAllowedStakingTokens(toks1);
        address[] memory toks1Fetched = staker.getAllowedStakingTokens();
        require(toks1Fetched.length == 3, "Toks1Fetched: Incorrect length");
        require(toks1Fetched[0] == tok1, "Toks1Fetched: Incorrect value");
        require(toks1Fetched[1] == tok2, "Toks1Fetched: Incorrect value");
        require(toks1Fetched[2] == tok3, "Toks1Fetched: Incorrect value");

        address[] memory toks2 = new address[](2);
        toks2[0] = tok2;
        toks2[1] = tok1;
        staker.removeAllowedStakingTokens(toks2);
        address[] memory toks2Fetched = staker.getAllowedStakingTokens();
        require(toks2Fetched.length == 1);
        require(toks2Fetched[0] == tok3);

        staker.addAllowedStakingTokens(toks2);
        address[] memory toks4Fetched = staker.getAllowedStakingTokens();
        require(toks4Fetched.length == 3);
        require(toks4Fetched[0] == tok3);
        require(toks4Fetched[1] == tok2);
        require(toks4Fetched[2] == tok1);
    }

    // Check the add and remove tokens for duplicate values and other invalid situations.
    function testAddRemoveTokensInvalid() public {
        address tok1 = address(1);
        address tok2 = address(2);
        address tok3 = address(3);
        address tok4 = address(4);

        // Error: Repeated token
        address[] memory toks1 = new address[](3);
        toks1[0] = tok1;
        toks1[1] = tok2;
        toks1[2] = tok1; // Repeat tok1
        vm.expectRevert();
        staker.addAllowedStakingTokens(toks1);

        // Add existing token
        address[] memory toks2 = new address[](3);
        toks2[0] = tok1;
        toks2[1] = tok2;
        toks2[2] = tok3;
        staker.addAllowedStakingTokens(toks2);
        address[] memory toks3 = new address[](1);
        toks3[0] = tok1;
        vm.expectRevert();
        staker.addAllowedStakingTokens(toks3);

        // Error: Remove token that isn't in the list
        address[] memory toks4 = new address[](1);
        toks4[0] = tok4;
        vm.expectRevert();
        staker.removeAllowedStakingTokens(toks1);
    }
}
