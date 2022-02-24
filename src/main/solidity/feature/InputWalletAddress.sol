pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputWalletAddress is StateMachine, TezosWallet {
    function requestAddress() internal {
        Terminal.input(tvm.functionId(requestAddressCallback), "Please input Tezos Wallet Address:", false);
    }

    function requestAddressCallback(string value) public {
        walletData.walletAddress = value;
        send(Event.Done);
    }
}
