pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Pauseble.sol";

contract CryptologiqCrowdsale is Pauseble
{
    using SafeMath for uint;

    uint public stage = 0;
    uint public softcap = 85000000e18;   // Softcap - 85,000,000 LOGIQ
    uint public hardcap = 420000000e18;  // HardCap - 420,000,000 LOGIQ
    bool public softcapReached;
    bool public hardcapReached;
    bool public refundIsAvailable;
    uint256 public weisRaised;  // how many weis was raised on crowdsale
    uint256 public tokensSold = 0;  // how many tokens was sold on crowdsale

    event SoftcapReached();
    event HardcapReached();
    event CrowdSaleFinished(string info);
    event RefundIsAvailable();

    address public ownerWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;

    mapping(address => uint) public balances;

    struct Ico {
        uint256 tokens;             // Tokens in crowdsale
        uint startDate;             // Date when crowsale will be starting, after its starting that property will be the 0
        uint endDate;               // Date when crowdsale will be stop
        uint8 discount;             // Discount
        uint8 discountFirstDayICO;  // Discount. Only for first stage ico
    }

    Ico public ICO;

    /*
    * Function confirm autosell
    *
    */
    function confirmSell(uint256 _amount) internal view
    returns(bool)
    {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }

    /*
    *  Make discount
    */
    function countDiscount(uint256 amount) internal view
    returns(uint256)
    {
        uint256 _amount = (amount.mul(DEC)).div(buyPrice);
        require(_amount > 0);

        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (3 == stage) {
            if (now <= ICO.startDate + 1 days)
            {
                _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            }
            else
            {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        }
        else if (4 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }

        return _amount;
    }

    /**
    * Function for change discount if need
    *
    */
    function changeDiscount(uint8 _discount) public onlyOwner
    returns (bool)
    {
        ICO = Ico (ICO.tokens, ICO.startDate, ICO.endDate, _discount, ICO.discountFirstDayICO);
        return true;
    }

    /**
    * Expanding of the functionality
    *
    * @param _numerator - Numerator - value (10000)
    * @param _denominator - Denominator - value (10000)
    *
    * example: price 1000 tokens by 1 ether = changeRate(1, 1000)
    */
    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
    returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator.mul(DEC)).div(_denominator);

        return true;
    }

    /*
    * Function show in contract what is now
    *
    */
    function crowdSaleStatus() internal constant
    returns (string)
    {
        if (1 == stage) {
            return "Private sale";
        }
        else if(2 == stage) {
            return "Pre-ICO";
        }
        else if (3 == stage) {
            return "ICO first stage";
        }
        else if (4 == stage) {
            return "ICO second stage";
        }
        else if (5 >= stage) {
            return "feature stage";
        }

        return "there is no stage at present";
    }

    /*
    * Sales manager
    *
    */
    function paymentManager(address sender, uint256 value) internal
    {
        uint256 discountValue = countDiscount(value);
        require(confirmSell(discountValue));

        sell(sender, discountValue);
        weisRaised = weisRaised.add(value);
        tokensSold = tokensSold.add(discountValue);

        if (now >= ICO.endDate) {
            pauseInternal();
            CrowdSaleFinished(crowdSaleStatus()); // if time is up
        }

        if (tokensSold >= softcap && !softcapReached) {
            SoftcapReached();
            softcapReached = true;
        }

        if (tokensSold >= hardcap) {
            HardcapReached();
            hardcapReached = true;
        }
    }

    /*
    * Function for selling tokens in crowd time.
    *
    */
    function sell(address _investor, uint256 _amount) internal
    {
        ICO.tokens = ICO.tokens.sub(_amount);
        availableSupply = availableSupply.sub(_amount);

        _transfer(this, _investor, _amount);
    }

    /*
    * Function for start crowdsale (any)
    *
    * @param _tokens - How much tokens will have the crowdsale - amount humanlike value (10000)
    * @param _startDate - When crowdsale will be start - unix timestamp (1512231703 )
    * @param _endDate - When crowdsale will be end - humanlike value (7) same as 7 days
    * @param _discount - Discount for the crowd - humanlive value (7) same as 7 %
    * @param _discount - Discount for the crowds first day - humanlive value (7) same as 7 %
    */
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        require(_tokens * DEC <= availableSupply);  // require to set correct tokens value for crowd
        ICO = Ico (_tokens * DEC, _startDate, _startDate + _endDate * 1 days , _discount, _discountFirstDayICO);
        stage = stage.add(1);
        unpauseInternal();
    }

    /**
    * Function for web3js, should be call when somebody will buy tokens from website. This function only delegator.
    *
    * @param _investor - address of investor (who payed)
    * @param _amount - ethereum
    */
    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

    /**
    * Function for adding discount
    *
    */
    function withDiscount(uint256 _amount, uint _percent) internal pure
    returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }

    function refund() public
    {
        require(refundIsAvailable && balances[msg.sender] > 0);
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    }

    function widthrawOwner(uint256 amount) public onlyOwner
    {
        require(softcapReached);
        ownerWallet.transfer(amount);
    }

    function finish() public onlyOwner
    {
        if (availableSupply < softcap) {
            RefundIsAvailable();
            refundIsAvailable = true;
        } else {
            widthrawOwner(this.balance);
        }
    }
}