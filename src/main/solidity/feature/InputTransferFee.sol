pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTransferFee is StateMachine, TezosWallet {
    function requestInputTransferFee() internal {
        AmountInput.get(tvm.functionId(inputFee), "Enter fee:",  6, 0, 1000e6);
    }

    function inputFee(uint128 value) public {
        walletData.current_transfer.fee = value;
        send(Event.Done);
    }
}