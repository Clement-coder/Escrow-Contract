// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MyERC1155 is ERC1155, Ownable, ERC1155Supply {
    uint256 public constant ARTWORK = 0;
    uint256 public constant MEMBERSHIP = 1;

    constructor() ERC1155("https://game.example/api/item/{id}.json") Ownable(msg.sender) {
        _mint(msg.sender, ARTWORK, 1000, "");
        _mint(msg.sender, MEMBERSHIP, 1, "");
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) public {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "ERC1155: caller is not owner nor approved");
        _burn(from, id, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC1155Supply)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
