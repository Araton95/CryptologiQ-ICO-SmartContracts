pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Ownable.sol";

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