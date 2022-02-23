pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputWalletAddress is StateMachine, TezosWallet {
    function requestInputAddress() internal {
        Terminal.input(tvm.functionId(setupTezosWalletAddress), "Please input Tezos Wallet Address:", false);
    }

    function setupTezosWalletAddress(string value) public {
        walletData.wallet_address = value;
        send(Event.Done);
    }
}