pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract InputTransferFee is StateMachine, TezosWallet {
    function requestTransferFee() internal {
        AmountInput.get(tvm.functionId(requestTransferFeeCallback), "Enter fee:",  6, 0, 1000e6);
    }

    function requestTransferFeeCallback(uint128 value) public {
        walletData.currentTransfer.fee = value;
        send(Event.Done);
    }
}
