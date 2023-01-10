// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockERC20 is ERC20 {
    
    constructor(string memory _name,string memory _shortName,uint256 amount) ERC20(_name,_shortName){
         _mint(msg.sender, amount);
    }

    function mint(address account,uint256 amount) external {
        _mint(account,  amount);
    }
}