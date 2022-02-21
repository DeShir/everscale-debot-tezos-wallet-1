pragma ton-solidity >= 0.53.0;

import "../interface/Terminal.sol";
import "../interface/Menu.sol";
import "../interface/Network.sol";
import "../interface/SigningBoxInput.sol";
import "../interface/AmountInput.sol";
import "../lib/TezosClient.sol";

enum Event {Start, Done, RequestBalance, ChangeWalletAddress, RequestSecret, StartTransaction}
enum State {Init, WaitingInputWalletAddress, WalletWasInitialized, BalanceRequested, WaitingSecretInput,
    WaitingInputTargetAddress, WaitingInputAmount, WaitingInputFee, WaitingConfirmation}


abstract contract Sendable {
    function send(Event sm_event, string param) public virtual;
}

abstract contract Stateable {


    function init_state() public returns(State) {
        return State.Init;
    }
}

struct TezosTransfer {
    string target_address;
    uint128 amount;
    uint128 fee;
}

abstract contract Contextable {
    struct Context {
        string wallet_address;
        uint32 sing_box_handle;
        TezosTransfer current_transfer;
    }

    Context context;

    function init_context() internal returns(Context) {
        return Context("", 0, TezosTransfer("", 0, 0));
    }
}

// Any -> WaitingInputWalletAddress
abstract contract Any_WaitingInputWalletAddress is Contextable, Sendable {

    function Any_WaitingInputWalletAddress_transition(State from, State to, string args) internal {
        if(State.WaitingInputWalletAddress == to) {
            Any_WaitingInputWalletAddress_action(args);
        }
    }

    function Any_WaitingInputWalletAddress_action(string args) private {
        Terminal.input(tvm.functionId(setupTezosWalletAddress), "Please input Tezos Wallet Address:", false);
    }

    function setupTezosWalletAddress(string value) public {
        context.wallet_address = value;
        this.send(Event.Done, "");
    }
}


// Any -> WalletWasInitialized
abstract contract Any_WalletWasInitialized is Contextable, Sendable {
    function Any_WalletWasInitialized_transition(State from, State to, string args) internal {
        if(State.WalletWasInitialized == to) {
            Any_WalletWasInitialized_action(args);
        }
    }

    function Any_WalletWasInitialized_action(string args) private {
        Menu.select("Main menu", "", [
                MenuItem("Check Balance", "", tvm.functionId(checkBalance)),
                MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddress)),
                MenuItem("Input secret", "", tvm.functionId(requestSecret)),
                MenuItem("Start Transaction", "", tvm.functionId(startTransaction))
            ]);
    }

    function checkBalance(uint32 index) public {
        this.send(Event.RequestBalance, "");
    }

    function changeWalletAddress(uint32 index) public {
        this.send(Event.ChangeWalletAddress, "");
    }

    function requestSecret(uint32 index) public {
        this.send(Event.RequestSecret, "");
    }

    function startTransaction(uint32 index) public {
        this.send(Event.StartTransaction, "");
    }
}

// Any -> BalanceRequested
abstract contract Any_BalanceRequested is Contextable, TezosClient, Sendable  {
    function Any_BalanceRequested_transition(State from, State to, string args) internal {
        if(State.BalanceRequested == to) {
            Any_BalanceRequested_action(args);
        }
    }

    function Any_BalanceRequested_action(string args) private {
        this.balance(context.wallet_address);
    }

    function balance_result(string value) internal override {
        Terminal.print(0, format("Balance: {}xtz", stoi(value).get() / 1000000.0));
        this.send(Event.Done, "");
    }
}

// Any -> WaitingSecretInput
abstract contract Any_WaitingSecretInput is Contextable, Sendable  {
    function Any_WaitingSecretInput_transition(State from, State to, string args) internal {
        if(State.WaitingSecretInput == to) {
            Any_WaitingSecretInput_action(args);
        }
    }

    function Any_WaitingSecretInput_action(string args) private {
        SigningBoxInput.get(tvm.functionId(sing_box_handle), "Provide your secret:", new uint256[](0));

    }

    function sing_box_handle(uint32 handle) public {
        context.sing_box_handle = handle;
        this.send(Event.Done, "");
    }
}

// Any -> WaitingInputTargetAddress
abstract contract Any_WaitingInputTargetAddress is Contextable, Sendable  {
    function Any_WaitingInputTargetAddress_transition(State from, State to, string args) internal {
        if(State.WaitingInputTargetAddress == to) {
            Any_WaitingInputTargetAddress_action(args);
        }
    }

    function Any_WaitingInputTargetAddress_action(string args) private {
        Terminal.input(tvm.functionId(setupTargetTezosWalletAddress), "Please input  target Tezos Wallet Address:", false);

    }

    function setupTargetTezosWalletAddress(string value) public {
        context.current_transfer.target_address = value;
        this.send(Event.Done, "");
    }
}

// Any -> WaitingInputAmount
abstract contract Any_WaitingInputAmount is Contextable, Sendable  {
    function Any_WaitingInputAmount_transition(State from, State to, string args) internal {
        if(State.WaitingInputAmount == to) {
            Any_WaitingInputAmount_action(args);
        }
    }

    function Any_WaitingInputAmount_action(string args) private {
        AmountInput.get(tvm.functionId(inputAmount), "Enter amount:",  6, 0, 1000e6);
    }

    function inputAmount(uint128 value) public {
        context.current_transfer.amount = value;
        this.send(Event.Done, "");
    }
}

// Any -> WaitingInputFee
abstract contract Any_WaitingInputFee is Contextable, Sendable  {
    function Any_WaitingInputFee_transition(State from, State to, string args) internal {
        if(State.WaitingInputFee == to) {
            Any_WaitingInputFee_action(args);
        }
    }

    function Any_WaitingInputFee_action(string args) private {
        AmountInput.get(tvm.functionId(inputFee), "Enter fee:",  6, 0, 1000e6);
    }

    function inputFee(uint128 value) public {
        context.current_transfer.fee = value;
        this.send(Event.Done, "");
    }
}

// Any -> WaitingConfirmation
abstract contract Any_WaitingConfirmation is Contextable, Sendable, TezosClientTransaction  {
    function Any_WaitingConfirmation_transition(State from, State to, string args) internal {
        if(State.WaitingConfirmation == to) {
            Any_WaitingConfirmation_action(args);
        }
    }

    function Any_WaitingConfirmation_action(string args) private {
        this.start_transaction(context.wallet_address, context.current_transfer.target_address,
            context.current_transfer.amount, context.current_transfer.fee, context.sing_box_handle);
    }

    function transaction_done(string operation_hash) public override {
        this.send(Event.Done, "");
    }
}


abstract contract Transitionable is
    Any_WaitingInputWalletAddress,
    Any_WalletWasInitialized,
    Any_BalanceRequested,
    Any_WaitingSecretInput,
    Any_WaitingInputTargetAddress,
    Any_WaitingInputAmount,
    Any_WaitingInputFee,
    Any_WaitingConfirmation {
    struct Transition {
        Event sm_event;
        State from;
        State to;
    }

    // {Start}                  Init                        ->  WaitingInputWalletAddress
    // {Done}                   WaitingInputWalletAddress   ->  WalletWasInitialized
    // {RequestBalance}         WalletWasInitialized        ->  BalanceRequested
    // {Done}                   BalanceRequested            ->  WalletWasInitialized
    // {ChangeWalletAddress}    WalletWasInitialized        ->  WaitingInputWalletAddress
    // {RequestSecret}          WalletWasInitialized        ->  WaitingSecretInput
    // {Done}                   WaitingSecretInput          ->  WalletWasInitialized
    // {StartTransaction}       WalletWasInitialized        ->  WaitingInputTargetAddress
    // {Done}                   WaitingInputTargetAddress   ->  WaitingInputAmount
    // {Done}                   WaitingInputAmount          ->  WaitingInputFee
    // {Done}                   WaitingInputFee             ->  WalletWasInitialized

    // TBD:
    // {Done}                   WaitingConfirmation         ->  WalletWasInitialized

    function init_transitions() public returns(Transition[]) {
        return [
            Transition(Event.Start,                     State.Init,                             State.WaitingInputWalletAddress),
            Transition(Event.Done,                      State.WaitingInputWalletAddress,        State.WalletWasInitialized),
            Transition(Event.RequestBalance,            State.WalletWasInitialized,             State.BalanceRequested),
            Transition(Event.Done,                      State.BalanceRequested,                 State.WalletWasInitialized),
            Transition(Event.ChangeWalletAddress,       State.WalletWasInitialized,             State.WaitingInputWalletAddress),
            Transition(Event.RequestSecret,             State.WalletWasInitialized,             State.WaitingSecretInput),
            Transition(Event.Done,                      State.WaitingSecretInput,               State.WalletWasInitialized),
            Transition(Event.StartTransaction,          State.WalletWasInitialized,             State.WaitingInputTargetAddress),
            Transition(Event.Done,                      State.WaitingInputTargetAddress,        State.WaitingInputAmount),
            Transition(Event.Done,                      State.WaitingInputAmount,               State.WaitingInputFee),
            Transition(Event.Done,                      State.WaitingInputFee,                  State.WaitingConfirmation),
            Transition(Event.Done,                      State.WaitingConfirmation,              State.WalletWasInitialized)

        ];
    }

    function transition(State from, State to, string arg) internal {
        Any_WaitingInputWalletAddress_transition(from, to, arg);
        Any_WalletWasInitialized_transition(from, to, arg);
        Any_BalanceRequested_transition(from, to, arg);
        Any_WaitingSecretInput_transition(from, to, arg);
        Any_WaitingInputTargetAddress_transition(from, to, arg);
        Any_WaitingInputAmount_transition(from, to, arg);
        Any_WaitingInputFee_transition(from, to, arg);
        Any_WaitingConfirmation_transition(from, to, arg);
    }
}