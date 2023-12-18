// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

/**
    @title ChainUtil
    @notice Utilities related to the chain id.
    @dev Not designed to be upgradeable.
 */
abstract contract ChainUtil {
    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
