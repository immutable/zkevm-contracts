// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import "../../src/common/AllowedStakingTokens.sol";


contract AllowedStakingTokensImpl is AllowedStakingTokens {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_ADMIN_ROLE, msg.sender);
    }
}
