pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTargetAddress is StateMachine, TezosWallet {
    function requestInputTargetAddress() internal {
        Terminal.input(tvm.functionId(setupTargetTezosWalletAddress), "Please input  target Tezos Wallet Address:", false);

    }

    function setupTargetTezosWalletAddress(string value) public {
        walletData.current_transfer.target_address = value;
        send(Event.Done);
    }
}
