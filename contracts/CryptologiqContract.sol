pragma solidity ^0.4.18;

import "./ERC20Extending.sol";
import "./CryptologiqCrowdsale.sol";

contract CryptologiqContract is ERC20Extending, CryptologiqCrowdsale
{
    /* Cryptologiq tokens Constructor */
    function CryptologiqContract() public TokenERC20(700000000, "CryptologiQ", "LOGIQ") {}

    /**
    * Function payments handler
    *
    */
    function () public payable
    {
        assert(msg.value >= 1 ether / 10);
        require(now >= ICO.startDate);

        if (paused == false) {
            paymentManager(msg.sender, msg.value);
        } else {
            revert();
        }
    }
}
