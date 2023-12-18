
// Copyright (c) Immutable Pty Ltd
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "../../src/common/ChainUtil.sol";

contract ChainUtilImpl is ChainUtil {

    constructor(uint256 _ethChainId) ChainUtil(_ethChainId) {
    }

    function isEthereumChainTest() external view returns (bool) {
        return isEthereumChain();
    }
}
