pragma solidity ^0.4.18;

import "./Ownable.sol";

contract Pausable is Ownable
{
    event EPause();
    event EUnpause();

    bool public paused = true;

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }

    function isPaused() view public returns(bool)
    {
        return paused;
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause();
    }
}