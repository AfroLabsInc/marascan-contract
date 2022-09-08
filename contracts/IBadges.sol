// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

interface IBadges {
    function mintBadge(uint256 id, address _to, uint256 amount) external;
}