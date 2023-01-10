// SPDX-License-Identifier: MIT
/*
https://watchchain.com/
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mock1155 is Ownable, ERC1155("") {

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _burn(from, id, amount);
    }
}
