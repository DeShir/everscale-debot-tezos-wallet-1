pragma ton-solidity >= 0.53.0;

import "../interface/Terminal.sol";
import "../interface/Menu.sol";
import "../interface/Network.sol";
import "../lib/TezosClient.sol";

enum Event {Start, Done, RequestBalance, ChangeWalletAddress}
enum State {Init, WaitingInputWalletAddress, WalletWasInitialized, BalanceRequested}


abstract contract Sendable {
    function send(Event sm_event, string param) public virtual;
}

abstract contract Finishable {
    function finish(bool is_success) public virtual;
}

abstract contract Stateable {


    function init_state() public returns(State) {
        return State.Init;
    }
}

abstract contract Contextable {
    struct Context {
        string wallet_address;
    }

    Context public context;

    function init_context() public returns(Context) {
        return Context("");
    }
}


// {Start}                  Init                        ->  WaitingInputWalletAddress
// {Done}                   WaitingInputWalletAddress   ->  WalletWasInitialized
// {RequestBalance}         WalletWasInitialized        ->  BalanceRequested
// {Done}                   BalanceRequested            ->  WalletWasInitialized
// {ChangeWalletAddress}    WalletWasInitialized        ->  WaitingInputWalletAddress

// Any -> WaitingInputWalletAddress
abstract contract Any_WaitingInputWalletAddress is Contextable, Finishable, Sendable {

    function Any_WaitingInputWalletAddress_transition(State from, State to, string args) public {
        if(State.WaitingInputWalletAddress == to) {
            Any_WaitingInputWalletAddress_action(args);
        }
    }

    function Any_WaitingInputWalletAddress_action(string args) private {
        Terminal.input(tvm.functionId(setupTezosWalletAddress), "Please input Tezos Wallet Address:", false);
        this.finish(true);
    }

    function setupTezosWalletAddress(string value) public {
        context.wallet_address = value;
        this.send(Event.Done, "");
    }
}


// Any -> WalletWasInitialized
abstract contract Any_WalletWasInitialized is Contextable, Finishable, Sendable {
    function Any_WalletWasInitialized_transition(State from, State to, string args) public {
        if(State.WalletWasInitialized == to) {
            Any_WalletWasInitialized_action(args);
        }
    }

    function Any_WalletWasInitialized_action(string args) private {
        // to do
        Menu.select("Main menu", "", [
            MenuItem("Check Balance", "", tvm.functionId(checkBalance)),
            MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddress))
            ]);
        this.finish(true);
    }

    function checkBalance(uint32 index) public {
        this.send(Event.RequestBalance, "");
    }

    function changeWalletAddress(uint32 index) public {
        this.send(Event.ChangeWalletAddress, "");
    }
}

// {CheckBalance} Any -> BalanceRequested
abstract contract Any_BalanceRequested is Contextable, Finishable, TezosClient, Sendable  {
    function Any_BalanceRequested_transition(State from, State to, string args) public {
        if(State.BalanceRequested == to) {
            Any_BalanceRequested_action(args);
        }
    }

    function Any_BalanceRequested_action(string args) private {
        // to do
        this.balance(context.wallet_address);
        this.finish(true);
    }

    function balance_result(string value) public override {
        Terminal.print(0, "Balance: " + value);
        this.send(Event.Done, "");
    }
}

abstract contract Transitionable is
    Any_WaitingInputWalletAddress,
    Any_WalletWasInitialized,
    Any_BalanceRequested {
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
    function init_transitions() public returns(Transition[]) {
        return [
            Transition(Event.Start,                     State.Init,                             State.WaitingInputWalletAddress),
            Transition(Event.Done,                      State.WaitingInputWalletAddress,        State.WalletWasInitialized),
            Transition(Event.RequestBalance,            State.WalletWasInitialized,             State.BalanceRequested),
            Transition(Event.Done,                      State.BalanceRequested,                 State.WalletWasInitialized),
            Transition(Event.ChangeWalletAddress,       State.WalletWasInitialized,             State.WaitingInputWalletAddress)
        ];
    }

    function transition(State from, State to, string arg) public {
        Any_WaitingInputWalletAddress_transition(from, to, arg);
        Any_WalletWasInitialized_transition(from, to, arg);
        Any_BalanceRequested_transition(from, to, arg);
    }
}