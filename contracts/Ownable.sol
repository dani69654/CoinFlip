pragma solidity ^0.5.12;

contract Ownable{
    address payable owner; // Variabile dove salverò l'indirizzo di chi fa il deploy dello smart contract che verrá considerato l'owner del contratto.

    constructor () public { // nel costruttore assegno alla variabile owner l'indirizzo di chi ha fatto il deploy del contratto.
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner, "This function is restricted to the owner");
        _;
    }
}
