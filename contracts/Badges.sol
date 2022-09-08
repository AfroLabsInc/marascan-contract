// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IBadges.sol";
contract DonorBadges is ERC1155, IBadges {
    constructor()
        ERC1155(
            "https://api.afroapes.com/v1/collections/afro-apes-collectibles/{id}"
        )
    {}

    function mintBadge(uint256 id, address to) external {
        _mint(to, id, 1, "");
    }


}
