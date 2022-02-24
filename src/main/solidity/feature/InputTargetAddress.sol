pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTargetAddress is StateMachine, TezosWallet {
    function requestDestinationAddress() internal {
        Terminal.input(tvm.functionId(requestDestinationAddressCallback), "Please input  target Tezos Wallet Address:", false);

    }

    function requestDestinationAddressCallback(string value) public {
        walletData.currentTransfer.destinationAddress = value;
        send(Event.Done);
    }
}
