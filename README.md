# Cryptologiq Token and Crowdsale Smart Contracts
[![Platform](https://img.shields.io/badge/Token%20Name-LOGIQ-aqua.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Ethereum-brightgreen.svg)](https://en.wikipedia.org/wiki/Ethereum)
[![Platform](https://img.shields.io/badge/Standard-ERC20-blue.svg)](https://en.wikipedia.org/wiki/ERC20)
[![Platform](https://img.shields.io/badge/Compiler-^0.4.18-yellow.svg)](http://solidity.readthedocs.io/en/v0.4.18/)

## Description
The CryptologiQ Token (LOGIQ) is an <a href="https://en.wikipedia.org/wiki/ERC20">ERC20</a> token created on the <a href="https://en.wikipedia.org/wiki/Ethereum">Ethereum</a> blockchain platform and build on <a href="http://truffleframework.com/">truffle framework </a>. The LOGIQ serves as a payment tool within the CryptologiQ ecosystem. 

## Token

| Token symbol  | LOGIQ |
| ------------- | ------------- |
| Token name  | CryptologiQ token  |
| Token type  | Utlity token  |
| Total fixed supply | 700,000,000 LOGIQ |
| Initial price | 1 ETH = 24,000 LOGIQ |
   
## Smart contracts

* SafeMath (Library)
* Ownable
* BasicToken
* ERC20
* ERC20Basic
* FreezableToken
* PausableToken
* StandardToken
* CryptologiqCrowdsale
* CryptologiQ

## Functions

`mul, div, add, sub` - Math operations with safety checks that throw on error

`totalSupply()` - Total number of tokens in existence

`balanceOf(address _owner)` - Gets the balance of the specified address

`transferOwnership(address newOwner)` - Allows the current owner to transfer control of the contract to a newOwner

`transfer(address _to, uint256 _value)` - Transfer token for a specified address

`transferFrom(address _from, address _to, uint256 _value)` - Transfer tokens from one address to another

`approve(address _spender, uint256 _value)` - Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.

`allowance(address _owner, address _spender)` - Function to check the amount of tokens that an owner allowed to a spender

`increaseApproval(address _spender, uint _addedValue)` - Increase the amount of tokens that an owner allowed to a spender

`decreaseApproval(address _spender, uint _subtractedValue)` - Decrease the amount of tokens that an owner allowed to a spender

`startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO)` - Start ICO phase

`changeRate(uint256 _numerator, uint256 _denominator)` - Change eth/token price rent (can call only owner)

`changeDiscount(uint8 _discount)` - Chage discount(bonus) price

`pause()` - Pause all functions (can call only owner)

`unpause()` - Unpause all functions (can call only owner of smart contract)

`burnAfterICO()` - Burn all remaining tokens after ICO (can call everyone)

`enableRefund()` - Enable refund for investors (if softcap didn't reached)

`getMyRefund()` - Get own refund after ICO finish (if softcap didn't reached)

`freezeAccount(address target)` - Freeze transaction for target account (can call only owner)

`unFreezeAccount(address target)` - Unfreeze transaction for target account (can call only owner)

`sell(address _investor, uint256 _amount)` - Sell tokens to investor

`countDiscount(uint256 amount)` - Count discounted price before sell it investor

`transferWeb3js(address _investor, uint256 _amount)` - Pass info to website

`transferEthFromContract(address _to, uint256 _amaunt)` - Transfer ETH from smart contract (can call only owner)

`transferTokensFromContract(address _to, uint256 _value)` - Transfer LOGIQ from smart contract (can call only owner)
