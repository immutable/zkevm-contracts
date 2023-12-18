// Copyright (c) Immutable Pty Ltd
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/common/Staker.sol";

contract StakerTest is Test {
    uint256 public constant ETHEREUM_MAINNET = 1;

    error Dump1(uint256);

    Staker public staker;


    function setUp() public {
        StakerInit memory init = StakerInit(
            msg.sender,         // superAdmin 
            msg.sender,         // tokenAdmin
            msg.sender,         // accountAdmin
            msg.sender,         // validator
            address(0),         // stakingTokenMinter
            address(0),         // stakingToken
            address(0),         // stakeManager
            ETHEREUM_MAINNET,   // ethereumChainId
            0,                  // childChainId
            address(0)          // exitHelper
        );
        staker = new Staker(init);
    }

    // function testGetValidator() public {
    //     address DUMMY_ADDRESS = address(1);
    //     staker = new Staker(msg.sender, msg.sender, msg.sender, DUMMY_ADDRESS, ETHEREUM_MAINNET);
    //     assertEq(staker.validator(), DUMMY_ADDRESS);
    // }

    // Check authentication
    function testAddRemoveTokensBadAuth() public {
        if (staker.validator() != msg.sender) {
            revert("Deployer doesn't equal msg.sender");
        }
        vm.startPrank(msg.sender);
        address tok1 = address(1);
        address tok2 = address(2);

        // Add a token
        address[] memory toks1 = new address[](1);
        toks1[0] = tok1;
        staker.addAllowedStakingTokens(toks1);

        // Now try to add and remove with an incorrect address (not the validator)
        vm.startPrank(address(20));

        // Expect to fail - bad auth
        address[] memory toks2 = new address[](1);
        toks2[0] = tok2;
        vm.expectRevert();
        staker.addAllowedStakingTokens(toks2);

        // Expect to fail - bad auth
        vm.expectRevert();
        staker.removeAllowedStakingTokens(toks1);
    }
}
