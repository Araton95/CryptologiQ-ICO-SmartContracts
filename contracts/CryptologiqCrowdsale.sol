pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./PausableToken.sol";

contract CryptologiqCrowdsale is PausableToken
{
    using SafeMath for uint;

    uint256 DEC = 10 ** uint256(decimals);
    uint256 public buyPrice = 1000000000000000000 wei;

    uint public stage = 0;
    uint256 public weisRaised = 0;
    uint256 public tokensSold = 0;

    uint public ICOdeadLine = 1530392400; // ICO end time - Sunday, 1 July 2018, 00:00:00.

    mapping (address => uint256) public deposited;

    modifier afterDeadline {
        require(now > ICOdeadLine);
        _;
    }

    uint256 public constant softcap = 85000000e18;
    uint256 public constant hardcap = 420000000e18;

    bool public softcapReached;
    bool public refundIsAvailable;
    bool public burned;

    event SoftcapReached();
    event HardcapReached();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event CrowdSaleFinished(string info);
    event Burned(address indexed burner, uint256 amount);

    struct Ico {
        uint256 tokens;             // Tokens in crowdsale
        uint startDate;             // Date when crowsale will be starting, after its starting that property will be the 0
        uint endDate;               // Date when crowdsale will be stop
        uint8 discount;             // Discount
        uint8 discountFirstDayICO;  // Discount. Only for first stage ico
    }

    Ico public ICO;

    function confirmSell(uint256 _amount) internal view
    returns(bool)
    {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }

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
            if (now <= ICO.startDate + 1 days) {
                _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            } else {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        }
        else if (4 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }

        return _amount;
    }

    function changeDiscount(uint8 _discount) public onlyOwner
    returns (bool)
    {
        ICO = Ico (ICO.tokens, ICO.startDate, ICO.endDate, _discount, ICO.discountFirstDayICO);
        return true;
    }

    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
    returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator.mul(DEC)).div(_denominator);

        return true;
    }

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

    function paymentManager(address sender, uint256 value) internal
    {
        uint256 discountValue = countDiscount(value);
        require(confirmSell(discountValue));

        sell(sender, discountValue);
        deposited[sender] = deposited[sender].add(value);
        weisRaised = weisRaised.add(value);
        tokensSold = tokensSold.add(discountValue);

        if ((tokensSold >= softcap) && !softcapReached) {
            softcapReached = true;
            SoftcapReached();
        }

        if (tokensSold == hardcap) {
            pauseInternal();
            HardcapReached();
            CrowdSaleFinished(crowdSaleStatus());
        }
    }

    function sell(address _investor, uint256 _amount) internal
    {
        ICO.tokens = ICO.tokens.sub(_amount);
        _transfer(this, _investor, _amount);
        Transfer(this, _investor, _amount);
    }

    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        require(_tokens * DEC <= balances[this]);

        ICO = Ico (_tokens * DEC, _startDate, _startDate + _endDate * 1 days , _discount, _discountFirstDayICO);
        stage = stage.add(1);
        unpauseInternal();
    }

    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure
    returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }

    function enableRefund() public afterDeadline
    {
        require(!softcapReached);

        refundIsAvailable = true;
        RefundsEnabled();
    }

    function getMyRefund() public afterDeadline
    {
        require(refundIsAvailable);
        require(deposited[msg.sender] > 0);

        uint256 depositedValue = deposited[msg.sender];
        deposited[msg.sender] = 0;
        msg.sender.transfer(depositedValue);
        Refunded(msg.sender, depositedValue);
    }

    function burnAfterICO() public afterDeadline
    {
        require(!burned);

        address burner = msg.sender;
        totalSupply = totalSupply.sub(balances[this]);
        balances[this] = balances[this].sub(balances[this]);
        burned = true;
        Burned(burner, balances[this]);
    }

    // Need discuss with Zorayr
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        ICO.tokens = ICO.tokens.sub(_value);
        balances[this] = balances[this].sub(_value);
        _transfer(this, _to, _value);
    }
}