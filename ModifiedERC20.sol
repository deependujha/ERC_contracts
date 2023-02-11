// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyCustomERC20Token is ERC20, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public taxCollector;

    constructor() ERC20("Web3Talent", "W3T") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        taxCollector = msg.sender;
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function changeTaxCollector(address _newTaxCollector) external onlyRole(DEFAULT_ADMIN_ROLE){
        taxCollector = _newTaxCollector;
    }

    function mintForWhitelistedAddr(address to, uint256 amount) internal onlyRole(MINTER_ROLE){
        _mint(to, amount);
    }

    function mint(address to, uint256 amount) public  {
        uint totalSupplyIfMinted = totalSupply()+amount;
        require(totalSupplyIfMinted <= 70000000000 * 10 **18,"All minted");

        if(totalSupplyIfMinted >= 50000000000 * 10**18){
            mintForWhitelistedAddr(to, amount);
        }
        else{
            _mint(to, amount);
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(balanceOf(owner)>=amount,"Not enough");
        uint tax = amount/20;
        if(owner != taxCollector){
            _transfer(owner, taxCollector, tax);
        }
        _transfer(owner, to, amount-tax);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
         uint tax = amount/20;
        if(from != taxCollector){
            _transfer(from, taxCollector, tax);
        }
        _transfer(from, to, amount-tax);
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
