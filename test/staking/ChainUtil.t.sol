
// Copyright (c) Immutable Pty Ltd
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./ChainUtilImpl.sol";

contract ChainUtilTest is Test {
    ChainUtilImpl public chainUtil;


    function setUp() public {
        //chainUtil = new ChainUtilImpl(1);
    }

    function testIsEthereumChainMainNet() public {
        chainUtil = new ChainUtilImpl(1);
        vm.chainId(1);
        assertTrue(chainUtil.isEthereumChainTest());
        vm.chainId(2);
        assertFalse(chainUtil.isEthereumChainTest());
        emit log_uint(block.chainid); 
    }

    function testIsEthereumChainSepolia() public {
        chainUtil = new ChainUtilImpl(11155111);
        vm.chainId(11155111);
        assertTrue(chainUtil.isEthereumChainTest());
        // Ensure this fails even if the chain is Ethereum MainNet
        vm.chainId(1);
        assertFalse(chainUtil.isEthereumChainTest());
        vm.chainId(2);
        assertFalse(chainUtil.isEthereumChainTest());
        emit log_uint(block.chainid); 
    }
}
