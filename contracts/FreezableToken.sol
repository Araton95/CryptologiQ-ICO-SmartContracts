pragma solidity ^0.4.18;

import "./Ownable.sol";

contract FreezableToken is Ownable
{
    event FrozenFunds(address target, bool frozen);

    mapping (address => bool) frozenAccount;

    function freezeAccount(address target) public onlyOwner
    {
        frozenAccount[target] = true;
        FrozenFunds(target, true);
    }

    function unFreezeAccount(address target) public onlyOwner
    {
        frozenAccount[target] = false;
        FrozenFunds(target, false);
    }

    function frozen(address _target) view public returns (bool)
    {
        return frozenAccount[_target];
    }
}