pragma solidity ^0.4.18;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a + b;

        assert(c >= a);

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable
{
    address owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract TokenERC20 is Ownable
{
    using SafeMath for uint;

    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply;
    uint256 public availableSupply;
    uint256 public buyPrice = 1000000000000000000 wei;

    uint public icoEndTime = 1530403200; // ICO end time - Sunday, 1 July 2018, 00:00:00.
    bool burned;

    address public companyWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public internalExchangeWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public bountyWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;
    address public tournamentsWallet = 0xD5B93C49c4201DB2A674A7d0FC5f3F733EBaDe80;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // freezeAccount() frozen()
    mapping (address => bool) frozenAccount;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burned(uint amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20( uint256 initialSupply, string tokenName, string tokenSymbol) public
    {
        totalSupply = initialSupply.mul(DEC);  // Update total supply with the decimal amount

        balanceOf[this] = (totalSupply.mul(60)).div(100);                    // Send 60% of tokens to smart contract wallet      420,000,000 LOGIQ
        balanceOf[companyWallet] = (totalSupply.mul(20)).div(100);           // Send 20% of tokens to company wallet             140,000,000 LOGIQ
        balanceOf[internalExchangeWallet] = (totalSupply.mul(10)).div(100);  // Send 10% of tokens to internal exchange wallet   70,000,000 LOGIQ
        balanceOf[bountyWallet] = (totalSupply.mul(5)).div(100);             // Send 5% of tokens to bounty wallet               35,000,000 LOGIQ
        balanceOf[tournamentsWallet] = (totalSupply.mul(5)).div(100);        // Send 5% of tokens to tournaments wallet          35,000,000 LOGIQ

        availableSupply = balanceOf[this];     // Show how much tokens on contract
        name = tokenName;                      // Set the name for display purposes
        symbol = tokenSymbol;                  // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     *
     * @param _from - address of the contract
     * @param _to - address of the investor
     * @param _value - tokens for the investor
     */
    function _transfer(address _from, address _to, uint256 _value) internal
    {
        // Check if not frozen
        require(!frozenAccount[msg.sender]);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);

        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success)
    {
        require(!frozenAccount[msg.sender]);                 // Check if not frozen
        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner
    returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;
        }
    }

    /**
     * Approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success)
    {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success)
    {
        uint oldValue = allowance[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    /**
     * Owner can set any account into freeze state. It is helpful in case if account holder has
     * lost his key and he want administrator to freeze account until account key is recovered
     * @param target The account address
     * @param freeze The state of account
     */
    function freezeAccount(address target, bool freeze) public onlyOwner
    {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function frozen(address _target) view public returns (bool)
    {
        return frozenAccount[_target];
    }

    /**
    *  Burn tokens
    *
    *  Called when ICO is closed. Burns the remaining tokens except the tokens reserved:
    *  - for company              (20% / 140.000.000)
    *  - for internal exchanges   (10% / 70.000.000)
    *  - for bounty community     (5% / 35.000.000)
    *  - for tournaments          (5% / 35.000.000)
    *
    *  Anybody may burn the tokens after ICO ended, but only once.
    *  this ensures that the owner will not posses a majority of the tokens.
    */
    function burn() public
    {
        // If tokens have not been burned already and the crowdsale ended
        if (!burned && now > icoEndTime) {
            totalSupply = totalSupply.sub(availableSupply);
            balanceOf[this] = balanceOf[this].sub(availableSupply);
            Burned(availableSupply);
            burned = true;
            availableSupply = 0;
        }
    }

}

contract Pauseble is TokenERC20
{
    event EPause();
    event EUnpause();

    bool public paused = true;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause();
    }
}

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