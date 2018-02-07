pragma solidity ^0.4.18;

import "./TokenERC20.sol";

contract ERC20Extending is TokenERC20
{
    using SafeMath for uint;

    /**
    * Function for transfer tokens from contract to any address
    *
    */
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        availableSupply = availableSupply.sub(_value);
        _transfer(this, _to, _value);
    }
}
