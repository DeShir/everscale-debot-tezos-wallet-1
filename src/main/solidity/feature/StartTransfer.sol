pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";

abstract contract StartTransfer is StateMachine, TezosWallet {
    function inputTransferData() internal {
        Terminal.input(tvm.functionId(requestDestinationAddressCallback), "Please input  target Tezos Wallet Address:", false);

    }

    function requestDestinationAddressCallback(string value) public {
        walletData.currentTransfer.destinationAddress = value;
        requestTransferAmount();
    }

    function requestTransferAmount() private {
        AmountInput.get(tvm.functionId(requestTransferAmountCallback), "Enter amount:",  6, 0, 1000e6);
    }

    function requestTransferAmountCallback(uint128 value) public {
        walletData.currentTransfer.amount = value;
        requestTransferFee();
    }

    function requestTransferFee() private {
        AmountInput.get(tvm.functionId(requestTransferFeeCallback), "Enter fee:",  6, 0, 1000e6);
    }

    function requestTransferFeeCallback(uint128 value) public {
        walletData.currentTransfer.fee = value;
        send(Event.Done);
    }
}
