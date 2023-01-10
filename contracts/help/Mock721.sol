// SPDX-License-Identifier: MIT
/*
https://watchchain.com/
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mock721 is Ownable, ERC721 {
    string private _baseURIstring = "";

    constructor(string memory _name,string memory _shortName) ERC721(_name,_shortName){
        _mint(msg.sender, 0);
    }

    function burnFrom(uint256 _tokenId) public {
        _requireMinted(_tokenId);
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _burn(_tokenId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseURIstring;
    }

    function mint(address to, uint256 tokenIds) external onlyOwner {
        _mint(to, tokenIds);
    }

    function setBaseURI(string memory baseURIstring) external onlyOwner {
        _baseURIstring = baseURIstring;
    }

    function exists(uint256 tokenId) public view returns(bool){
        return _exists(tokenId);
    }
}
