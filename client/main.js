const web3 = new Web3(Web3.givenProvider);
const contractAddress = '0xb136738394C3E93A4E9F20a1B769b976a3fD0a7D';
var contract;

$(document).ready(async() => {
  contract = new web3.eth.Contract(abi,contractAddress);
  await connectMetamask();

  $('#playBt').click( async () => {
    await play();
  });

  //EVENT LISTENERS

  contract.once('LogNewProvableQuery', 
  {
    filter: { player: await getPlayerAddress() },
    fromBlock: 'latest'
  }, (error, event) => {
    if(error) throw("Error fetching events");
    jQuery("#events").text(`User ${event.returnValues.player} is waiting for the flip result`);
  });

  contract.once('FlipResult', 
  {
    filter: { player: await getPlayerAddress() },
    fromBlock: 'latest'
  }, (error, event) => {
    if(error) throw("Error fetching events");
    jQuery("#events").text(`User ${event.returnValues.player} won: ${event.returnValues.won}`);
  });
});

async function connectMetamask() {
  if (typeof window.ethereum !== undefined) { 
    const accounts = await web3.eth.requestAccounts();  
    let p = await getPlayerAddress();
    jQuery("#playerAddress").text(p);
  }
}

async function getPlayerAddress() {
  const playerAddr = await web3.eth.getAccounts();
  if(playerAddr[0] !== undefined) {
    return web3.utils.toChecksumAddress(playerAddr[0]);
  }
}

async function play() {
  let betAmt =  $("#betAmountSelector").val();
  let choice =  $("#betOnSelector").val();
  jQuery("#btAm").text(betAmt);
  jQuery("#plCh").text(choice);
  if(choice === 'Head'){
    choice = 0;
  } else {
    choice = 1;
  }
  await contract.methods.flip(choice).send({ from: await getPlayerAddress(), value:web3.utils.toWei(betAmt) });
}

// @dev               Use the console to run this function. Just deposit() and MetaMask will ask confirmation.
async function deposit() {
  await contract.methods.deposit().send({ from: await getPlayerAddress(), value:web3.utils.toWei('1') });
}