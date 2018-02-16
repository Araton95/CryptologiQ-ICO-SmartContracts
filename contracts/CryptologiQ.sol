pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./CryptologiqCrowdsale.sol";

contract CryptologiQ is CryptologiqCrowdsale
{
    using SafeMath for uint;

    address public companyWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public internalExchangeWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public bountyWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public tournamentsWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;

    function CryptologiQ() public
    {
        balances[this] = (totalSupply.mul(60)).div(100);                    // Send 60% of tokens to smart contract wallet      420,000,000 LOGIQ
        balances[companyWallet] = (totalSupply.mul(20)).div(100);           // Send 20% of tokens to company wallet             140,000,000 LOGIQ
        balances[internalExchangeWallet] = (totalSupply.mul(10)).div(100);  // Send 10% of tokens to internal exchange wallet   70,000,000 LOGIQ
        balances[bountyWallet] = (totalSupply.mul(5)).div(100);             // Send 5%  of tokens to bounty wallet              35,000,000 LOGIQ
        balances[tournamentsWallet] = (totalSupply.mul(5)).div(100);        // Send 5%  of tokens to tournaments wallet         35,000,000 LOGIQ
    }

    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        require(softcapReached);
        _to.transfer(amount);
    }

    function () public payable
    {
        require(now >= ICO.startDate);
        require(now < ICOdeadLine);

        assert(msg.value >= 1 ether / 100);

        if ((now > ICO.endDate) || (ICO.tokens == 0)) {
            pauseInternal();
            CrowdSaleFinished(crowdSaleStatus());

            revert();
        } else {
            paymentManager(msg.sender, msg.value);
        }
    }
}
