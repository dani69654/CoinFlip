import "./Ownable.sol";
pragma solidity 0.5.12;

contract Destroyable is Ownable{

    function killContract () public onlyOwner{
        selfdestruct (owner);
    }


}
