pragma solidity ^0.4.18;

import "./ERC20Extending.sol";
import "./CryptologiqCrowdsale.sol";

contract CryptologiqContract is ERC20Extending, CryptologiqCrowdsale
{
    using SafeMath for uint;

    uint public weisRaised;  // how many weis was raised on crowdsale

    /* Cryptologiq tokens Constructor */
    function CryptologiqContract() public TokenERC20(700000000, "Cryptologiq", "LOGIQ") {} //change before send !!!

    /**
    * Function payments handler
    *
    */
    function () public payable
    {
        assert(msg.value >= 1 ether / 10);
        require(now >= ICO.startDate);

        if (now >= ICO.endDate) {
            pauseInternal();
            CrowdSaleFinished(crowdSaleStatus());
        }


        if (0 != startIcoDate) {
            if (now < startIcoDate) {
                revert();
            } else {
                startIcoDate = 0;
            }
        }

        if (paused == false) {
            sell(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
        }
    }
}
