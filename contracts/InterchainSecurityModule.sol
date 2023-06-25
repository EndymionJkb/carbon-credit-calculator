
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IMultisigIsm.sol";

contract InterchainSecurityModule is IMultisigIsm  {
    /// @inheritdoc IInterchainSecurityModule
    function moduleType() external pure override returns (uint8) {
        return 3; // IInterchainSecurityModule.Types = LEGACY_MULTISIG
    }

    /// @inheritdoc IInterchainSecurityModule
    function verify(bytes calldata, bytes calldata)
        external
        pure
        override
        returns (bool) {
            return true;
        }

    /// @inheritdoc IMultisigIsm
    function validatorsAndThreshold(bytes calldata)
        external
        pure
        override
        returns (address[] memory validators, uint8 threshold) {
            validators = new address[](1);

            // abacus, from https://docs.hyperlane.xyz/docs/resources/security
            validators[0] = 0x59A001C3451E7f9F3b4759Ea215382c1e9aa5fC1;
            
            threshold = 1;
        }
}
