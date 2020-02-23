import "./provableAPI.sol";
import "./Ownable.sol";
import "./Destroyable.sol";

pragma solidity 0.5.12;

contract CoinFlip is Ownable, usingProvable, Destroyable {

  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint private mainContractBalance;


  event balanceUpdated (bool done);
  event LogNewProvableQuery (string queryRequested);
  event generatedRandomNumber(uint256 randomNumber);
  event flipResult (string result);

  constructor () public {
    provable_setProof(proofType_Ledger);
  }

  modifier costs (){
      require (msg.value >= 0.1 ether ,"Min bet is 0.1 Ether");
      _;
  }

  struct User {
    bytes32 id;
    address playerAddress;
  }

  struct UserByAdress {
    address payable playerAddress;
    uint customerBalance;
    uint choice;
    uint bet;
    bool inGame;
  }

  mapping (bytes32 => User) public player;
  mapping (address => UserByAdress) public playerByAddress;




  function flip (uint decision) payable public  {
     require (msg.value <= getMainContractBalance ()/2 + provable_getPrice("random"), "Bet must be higher than the oracle cost + double the amount deposited in the contract");
     require (playerByAddress[msg.sender].inGame == false, "You are currently in game, cannot start a new one yet");
     playerByAddress[msg.sender].playerAddress = msg.sender;
     playerByAddress[msg.sender].choice = decision;
     playerByAddress[msg.sender].bet = msg.value - provable_getPrice("random");
     playerByAddress[msg.sender].inGame = true;

   update();
  }

  function update() payable public costs() {
    // Call the oracle and populare the struct "User";
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK =200000;
    bytes32 query_id = provable_newRandomDSQuery(QUERY_EXECUTION_DELAY, NUM_RANDOM_BYTES_REQUESTED, GAS_FOR_CALLBACK);

    player[query_id].id = query_id;
    player[query_id].playerAddress = msg.sender;

    emit LogNewProvableQuery ("Provable query was sent, waiting for the callback");
  }


  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    if (
      provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        ) {
        } else {

    require (msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result)))%2;

    verifyResult (randomNumber, _queryId);
    emit generatedRandomNumber (randomNumber);
    }
  }


  function verifyResult (uint randomNumber, bytes32 _queryId) private {
    if(randomNumber == playerByAddress[player[_queryId].playerAddress].choice){
    playerByAddress[player[_queryId].playerAddress].customerBalance += playerByAddress[player[_queryId].playerAddress].bet;
    mainContractBalance -= playerByAddress[player[_queryId].playerAddress].bet;
    emit flipResult ("won");
    } else {
    mainContractBalance += playerByAddress[player[_queryId].playerAddress].bet;
    emit flipResult ("lost");
    }
    playerByAddress[player[_queryId].playerAddress].bet = 0;
    playerByAddress[player[_queryId].playerAddress].inGame = false;
  }


  function withdrawalAll () public onlyOwner {
    msg.sender.transfer(getContractBalance());
    assert(getContractBalance()==0);
    killContract ();
  }


  function withdrawalCustomerFunds () public payable {
     uint amountToWithdraw = playerByAddress[msg.sender].customerBalance;
     playerByAddress[msg.sender].customerBalance = 0;
     playerByAddress[msg.sender].playerAddress.transfer(amountToWithdraw*2);
     emit balanceUpdated (true);
  }


  function getCustomerBalance () public view returns (uint){
    return playerByAddress[msg.sender].customerBalance;
  }


  function getContractBalance () public view returns (uint){
    return address(this).balance;
  }


  function getMainContractBalance () public view returns (uint){
    return mainContractBalance;
  }


  function setContractBalance () public payable{
    mainContractBalance += msg.value;
    emit balanceUpdated(true);
  }


}
