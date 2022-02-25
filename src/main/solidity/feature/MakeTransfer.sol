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

    struct TransactionData {
        string source;
        string target;
        uint128 amount;
        uint128 fee;
        string branch;
        string protocol;
        int256 counter;
        string transactionHex;
        string transactionSign;
        uint32 singBoxHandle;
        int count;
    }

    TransactionData private transactionData;

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
        requestConfirmation();
    }

    function requestConfirmation() private {
        transactionData = TransactionData(walletData.walletAddress,
            walletData.currentTransfer.destinationAddress,
            walletData.currentTransfer.amount,
            walletData.currentTransfer.fee, "", "", 0, "", "", walletData.singBoxHandle, 3);

        string url;
        url = Net.tezosUrl("/chains/main/blocks/head/header");
        url.get(tvm.functionId(requestHeaderCallback));
        url = Net.tezosUrl("/chains/main/blocks/head/metadata");
        url.get(tvm.functionId(requestMetadataCallback));
        url = Net.tezosUrl("/chains/main/blocks/head/context/contracts/" + walletData.walletAddress);
        url.get(tvm.functionId(requestContractCallback));
    }

    function requestHeaderCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseHeaderCallback), content);
    }
    function requestMetadataCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseNextProtocolCallback), content);
    }
    function requestContractCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseCounterCallback), content);
    }

    function parseHeaderCallback(bool result, JsonLib.Value obj) public {
        transactionData.branch = obj.hash().get();
        transactionData.count -= 1;
        requestedDataIsComplete();
    }

    function parseNextProtocolCallback(bool result, JsonLib.Value obj) public {
        transactionData.protocol = obj.nextProtocol().get();
        transactionData.count -= 1;
        requestedDataIsComplete();
    }

    function parseCounterCallback(bool result, JsonLib.Value obj) public {
        transactionData.counter = obj.counter().get();
        transactionData.count -= 1;
        requestedDataIsComplete();
    }

    function requestedDataIsComplete() private {
        if(transactionData.count == 0) {
            requestTransactionForge();
        }
    }

    function requestTransactionForge() private {
        string url = Net.tezosUrl("/chains/main/blocks/head/helpers/forge/operations");

        TezosJSON.Transaction transaction = TezosJSON.Transaction(transactionData.branch, transactionData.source,
            transactionData.target, transactionData.amount,
            transactionData.fee, transactionData.counter);


        url.post(tvm.functionId(requestTransactionForgeCallback), transaction.forgeTransactionRequest());
    }

    function requestTransactionForgeCallback(int32 statusCode, string[] retHeaders, string content) public {
        Json.parse(tvm.functionId(parseTransactionForgeCallback), content);
    }

    function parseTransactionForgeCallback(bool result, JsonLib.Value obj) public {
        if(obj.as_string().hasValue()) {
            transactionData.transactionHex = obj.as_string().get();
            ConfirmInput.get(tvm.functionId(confirmTransactionCallback), format("Confirm transaction. Transfer {} xtz, (fee = {} xtz) from {}, to {}",
                transactionData.amount / 1000000.0, transactionData.fee / 1000000.0, transactionData.source, transactionData.target));
        } else {
            send(Event.Done);
        }
    }

    function confirmTransactionCallback(bool value) public {
        // todo if transaction is not confirmed sm should be moved to wallet initialized state
        if(value) {
            string url = Net.helperUrl("/hash/blake/" + "03" + transactionData.transactionHex);
            url.get(tvm.functionId(blakeTransactionCallback));
        } else {
            send(Event.Done);
        }
    }

    function blakeTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        Sdk.signHash(tvm.functionId(signTransactionCallback), transactionData.singBoxHandle, uint256(stoi("0x" + content).get()));
    }

    function signTransactionCallback(bytes signature) public {
        Hex.encode(tvm.functionId(injectTransaction), signature);
    }

    function injectTransaction(string hexstr) public {
        string url = Net.tezosUrl("/injection/operation");
        transactionData.transactionSign = hexstr;
        url.post(tvm.functionId(injectTransactionCallback), "\"" + transactionData.transactionHex + hexstr + "\"");
    }

    function injectTransactionCallback(int32 statusCode, string[] retHeaders, string content) public {
        send(Event.Done);
    }
}
