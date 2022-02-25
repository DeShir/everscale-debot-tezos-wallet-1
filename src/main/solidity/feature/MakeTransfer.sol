pragma ton-solidity >= 0.53.0;

import "../interface/_all.sol";
import "../sm/_all.sol";
import "../wallet/_all.sol";
import "../lib/_all.sol";

abstract contract MakeTransfer is StateMachine, TezosWallet {
    using TezosJSON for JsonLib.Value;
    using TezosJSON for TezosJSON.Transaction;
    using JsonLib for JsonLib.Value;
    using Net for string;

    int private countTezosInformationRequests;


    TezosJSON.Transaction transaction;
    string private forgeTransactionData;


    function inputTransferData() internal {
        transaction = TezosJSON.Transaction("", walletData.walletAddress, "", 0, 0, 0);
        Terminal.input(tvm.functionId(requestDestinationAddressCallback), "Please input  target Tezos Wallet Address:", false);

    }

    function requestDestinationAddressCallback(string value) public {
        transaction.destination = value;
        AmountInput.get(tvm.functionId(requestTransferAmountCallback), "Enter amount:",  6, 0, 1000e6);
    }

    function requestTransferAmountCallback(uint128 value) public {
        transaction.amount = value;
        AmountInput.get(tvm.functionId(requestTransferFeeCallback), "Enter fee:",  6, 0, 1000e6);
    }

    function requestTransferFeeCallback(uint128 value) public {
        transaction.fee = value;

        countTezosInformationRequests = 2;

        string url;
        url = Net.tezosUrl("/chains/main/blocks/head/header");
        url.get(tvm.functionId(requestHeaderCallback));
        url = Net.tezosUrl("/chains/main/blocks/head/context/contracts/" + walletData.walletAddress);
        url.get(tvm.functionId(requestContractCallback));
    }

    function requestHeaderCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseHeaderCallback), content);
    }

    function requestContractCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseCounterCallback), content);
    }

    function parseHeaderCallback(bool result, JsonLib.Value obj) public {
        transaction.branch = obj.hash().get();
        countTezosInformationRequests -= 1;
        isRequestedDataCompleted();
    }

    function parseCounterCallback(bool result, JsonLib.Value obj) public {
        transaction.counter = obj.counter().get();
        countTezosInformationRequests -= 1;
        isRequestedDataCompleted();
    }

    function isRequestedDataCompleted() private {
        if(countTezosInformationRequests == 0) {
            requestTransactionForge();
        }
    }

    function requestTransactionForge() private {
        string url = Net.tezosUrl("/chains/main/blocks/head/helpers/forge/operations");
        url.post(tvm.functionId(requestTransactionForgeCallback), transaction.forgeTransactionRequest());
    }

    function requestTransactionForgeCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseTransactionForgeCallback), content);
    }

    function parseTransactionForgeCallback(bool result, JsonLib.Value obj) public {
        if(obj.as_string().hasValue()) {
            forgeTransactionData = obj.as_string().get();
            ConfirmInput.get(tvm.functionId(confirmTransactionCallback), format("Confirm transaction. Transfer {} xtz, (fee = {} xtz) from {}, to {}",
                transaction.amount / 1000000.0, transaction.fee / 1000000.0, walletData.walletAddress, transaction.destination));
        } else {
            send(Event.Done);
        }
    }

    function confirmTransactionCallback(bool value) public {
        // todo if transaction is not confirmed sm should be moved to wallet initialized state
        if(value) {
            string url = Net.helperUrl("/hash/blake/" + "03" + forgeTransactionData);
            url.get(tvm.functionId(blakeTransactionCallback));
        } else {
            send(Event.Done);
        }
    }

    function blakeTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        Sdk.signHash(tvm.functionId(signTransactionCallback), walletData.singBoxHandle, uint256(stoi("0x" + content).get()));
    }

    function signTransactionCallback(bytes signature) public {
        Hex.encode(tvm.functionId(injectTransaction), signature);
    }

    function injectTransaction(string hexstr) public {
        string url = Net.tezosUrl("/injection/operation");
        url.post(tvm.functionId(injectTransactionCallback), "\"" + forgeTransactionData + hexstr + "\"");
    }

    function injectTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        send(Event.Done);
    }
}
