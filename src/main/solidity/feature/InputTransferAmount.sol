pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTransferAmount is StateMachine, TezosWallet {
    function requestTransferAmount() internal {
        AmountInput.get(tvm.functionId(requestTransferAmountCallback), "Enter amount:",  6, 0, 1000e6);
    }

    function requestTransferAmountCallback(uint128 value) public {
        walletData.currentTransfer.amount = value;
        send(Event.Done);
    }
}
