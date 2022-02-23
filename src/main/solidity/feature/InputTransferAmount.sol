pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTransferAmount is StateMachine, TezosWallet {
    function requestInputTransferAmount() internal {
        AmountInput.get(tvm.functionId(inputAmount), "Enter amount:",  6, 0, 1000e6);
    }

    function inputAmount(uint128 value) public {
        walletData.current_transfer.amount = value;
        send(Event.Done);
    }
}