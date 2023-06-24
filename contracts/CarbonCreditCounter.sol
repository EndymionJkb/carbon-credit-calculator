// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
  enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
  }

  function getInternalBalance(
    address user,
    IERC20[] memory tokens
  ) external view returns (uint256[] memory);

  function getPoolTokens(
    bytes32 poolId
  )
    external
    view
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );

  function getPool(
    bytes32 poolId
  ) external view returns (address, PoolSpecialization);
}

contract CarbonCreditCounter {
  address public constant BALANCER_VAULT =
    0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  // In principal we could have multiple pools, but with different types, etc., each one might be different
  // So hard-code the most important one
  bytes32 public constant BALANCER_BCT_POOL_ID =
    0x16faf9f73748013155b7bc116a3008b57332d1e600020000000000000000006d;

  // The list of carbon tokens we are measuring; would be different addresses on different chains
  IERC20[] private _carbonTokens;

  // Their relative weights (e.g., tons per token)
  uint256[] private _tokenWeights;

  /**
   * @dev Error thrown if you try to look at the zero address
   */
  error InvalidAddress();

  /**
   * @dev Error thrown if tokens and weight arrays do not match.
   */
  error InputLengthMismatch();

  constructor(IERC20[] memory carbonTokens, uint256[] memory tokenWeights) {
    if (carbonTokens.length != tokenWeights.length) {
      revert InputLengthMismatch();
    }

    if (carbonTokens.length > 0) {
      _carbonTokens = new IERC20[](carbonTokens.length);
      _tokenWeights = new uint256[](carbonTokens.length);

      for (uint256 i = 0; i < carbonTokens.length; i++) {
        _carbonTokens[i] = carbonTokens[i];
        _tokenWeights[i] = tokenWeights[i];
      }
    }
  }

  /**
   * @dev Check the wallet, internal balance, and pool for tokens
   * @param user - the account we are checking for credits
   */
  function getTotalCarbonCredits(address user) external view returns (uint256) {
    if (user == address(0)) {
      revert InvalidAddress();
    }

    // Are they an LP in the pool?
    uint256 poolBalance;

    (address poolAddress, ) = IVault(BALANCER_VAULT).getPool(
      BALANCER_BCT_POOL_ID
    );

    uint256 bptBalance = IERC20(poolAddress).balanceOf(user);

    if (bptBalance > 0) {
      uint256 totalSupply = IERC20(poolAddress).totalSupply();

      // This is an immutable 50/50 pool with USDC/BCT - BCT is the 2nd token
      (, uint256[] memory balances, ) = IVault(BALANCER_VAULT).getPoolTokens(
        BALANCER_BCT_POOL_ID
      );

      // The user holds bptBalance/totalSupply of the BCT token
      poolBalance = (balances[1] * bptBalance) / totalSupply;
    }

    return _getWalletBalances(user) + _getInternalBalances(user) + poolBalance;
  }

  function _getWalletBalances(
    address user
  ) private view returns (uint256 totalCredits) {
    for (uint256 i = 0; i < _carbonTokens.length; i++) {
      totalCredits += _carbonTokens[i].balanceOf(user) * _tokenWeights[i];
    }
  }

  function _getInternalBalances(
    address user
  ) private view returns (uint256 totalCredits) {
    uint256[] memory internalBalances = IVault(BALANCER_VAULT)
      .getInternalBalance(user, _carbonTokens);

    for (uint256 i = 0; i < _carbonTokens.length; i++) {
      totalCredits += internalBalances[i] * _tokenWeights[i];
    }
  }
}
