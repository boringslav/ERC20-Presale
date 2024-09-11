// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ERC20} from "solady/tokens/ERC20.sol";

contract ERC20Mock is ERC20 {
    string private s_name;
    string private s_symbol;

    constructor(string memory _name, string memory _symbol) ERC20() {
        s_name = _name;
        s_symbol = _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return s_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return s_symbol;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
