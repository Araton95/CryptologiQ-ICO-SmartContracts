pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./ERC20Basic.sol";
import "./FreezableToken.sol";

contract BasicToken is ERC20Basic, FreezableToken
{
    using SafeMath for uint256;

    string public constant name = "CryptologiQ";
    string public constant symbol = "LOGIQ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 700000000e18;

    mapping(address => uint256) balances;

    function totalSupply() public view returns (uint256)
    {
        return totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal
    {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }
}