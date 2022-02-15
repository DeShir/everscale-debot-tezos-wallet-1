pragma ton-solidity >=0.35.0;

import "../interface/Terminal.sol";
import "../interface/Menu.sol";
import "../interface/Network.sol";
import "../lib/TezosClient.sol";

enum Event {Start, TextEntered, CheckBalance, ChangeWalletAddress}

abstract contract Sendable {
    function send(Event sm_event, string param) public virtual;
}

abstract contract Finishable {
    function finish(bool is_success) public virtual;
}

abstract contract Stateable {
    enum State {Init, WaitingInputWalletAddress, WalletWasInitialized}

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


// {Start}                  Init                        ->  WaitingInputWalletAddress : Show Input Address Field
// {TextEntered}            WaitingInputWalletAddress   ->  WalletWasInitialized      : Show Menu with one item
// {CheckBalance}           WalletWasInitialized        ->  WalletWasInitialized      : Show Balance and Menu again
// {ChangeWalletAddress}    WalletWasInitialized        ->  WaitingInputWalletAddress : Show Input Address Field

// {Start} Init -> WaitingInputWalletAddress
abstract contract Init_WaitingInputWalletAddress is Contextable, Finishable, Sendable {
    function Init_WaitingInputWalletAddress_transition() public returns(Transitionable.Transition) {
        return Transitionable.Transition(Stateable.State.Init, Stateable.State.WaitingInputWalletAddress, Event.Start);
    }

    function Init_WaitingInputWalletAddress_checkAndExecute(Stateable.State from, Stateable.State to, string args) public {
        if(Stateable.State.Init == from && Stateable.State.WaitingInputWalletAddress == to) {
            Init_WaitingInputWalletAddress_action(args);
        }
    }

    function Init_WaitingInputWalletAddress_action(string args) private {
        Terminal.input(tvm.functionId(setupTezosWalletAddress), "Please input Tezos Wallet Address:", false);
        this.finish(true);
    }

    function setupTezosWalletAddress(string value) public {
        context.wallet_address = value;
        this.send(Event.TextEntered, "");
    }
}


// {TextEntered} WaitingInputWalletAddress -> WalletWasInitialized
abstract contract WaitingInputWalletAddress_WalletWasInitialized is Contextable, Finishable, Sendable {
    function WaitingInputWalletAddress_WalletWasInitialized_transition() public returns(Transitionable.Transition) {
        return Transitionable.Transition(Stateable.State.WaitingInputWalletAddress, Stateable.State.WalletWasInitialized, Event.TextEntered);
    }

    function WaitingInputWalletAddress_WalletWasInitialized_checkAndExecute(Stateable.State from, Stateable.State to, string args) public {
        if(Stateable.State.WaitingInputWalletAddress == from && Stateable.State.WalletWasInitialized == to) {
            WaitingInputWalletAddress_WalletWasInitialized_action(args);
        }
    }

    function WaitingInputWalletAddress_WalletWasInitialized_action(string args) private {
        // to do
        Menu.select("Main menu", "", [
            MenuItem("Check Balance", "", tvm.functionId(checkBalance)),
            MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddress))
            ]);
        this.finish(true);
    }

    function checkBalance(uint32 index) public {
        this.send(Event.CheckBalance, "");
    }

    function changeWalletAddress(uint32 index) public {
        this.send(Event.ChangeWalletAddress, "");
    }
}

// {CheckBalance} WalletWasInitialized -> WalletWasInitialized
abstract contract WalletWasInitialized_WalletWasInitialized is Contextable, Finishable, TezosClient, Sendable  {
    function WalletWasInitialized_WalletWasInitialized_transition() public returns(Transitionable.Transition) {
        return Transitionable.Transition(Stateable.State.WalletWasInitialized, Stateable.State.WalletWasInitialized, Event.CheckBalance);
    }

    function WalletWasInitialized_WalletWasInitialized_checkAndExecute(Stateable.State from, Stateable.State to, string args) public {
        if(Stateable.State.WalletWasInitialized == from && Stateable.State.WalletWasInitialized == to) {
            WalletWasInitialized_WalletWasInitialized_action(args);
        }
    }

    function WalletWasInitialized_WalletWasInitialized_action(string args) private {
        // to do
        this.balance(tvm.functionId(printBalance), context.wallet_address);
    }

    function printBalance(int32 statusCode, string[] retHeaders, string content) public {
        Terminal.print(0, "Balance: " + content);
        Menu.select("Main menu", "", [
            MenuItem("Check Balance", "", tvm.functionId(checkBalance1)),
            MenuItem("Change Wallet Address", "", tvm.functionId(changeWalletAddress1))
            ]);
        this.finish(true);
    }

    function checkBalance1(uint32 index) public {
        this.send(Event.CheckBalance, "");
    }

    function changeWalletAddress1(uint32 index) public {
        this.send(Event.ChangeWalletAddress, "");
    }
}


// {ChangeWalletAddress} WalletWasInitialized -> WaitingInputWalletAddress
abstract contract WalletWasInitialized_WaitingInputWalletAddress is Contextable, Finishable, Sendable {
    function WalletWasInitialized_WaitingInputWalletAddress_transition() public returns(Transitionable.Transition) {
        return Transitionable.Transition(Stateable.State.WalletWasInitialized, Stateable.State.WaitingInputWalletAddress, Event.ChangeWalletAddress);
    }

    function WalletWasInitialized_WaitingInputWalletAddress_checkAndExecute(Stateable.State from, Stateable.State to, string args) public {
        if(Stateable.State.WalletWasInitialized == from && Stateable.State.WaitingInputWalletAddress == to) {
            WalletWasInitialized_WaitingInputWalletAddress_action(args);
        }
    }

    function WalletWasInitialized_WaitingInputWalletAddress_action(string args) private {
        Terminal.input(tvm.functionId(setupTezosWalletAddress1), "Please input Tezos Wallet Address:", false);
        this.finish(true);
    }

    function setupTezosWalletAddress1(string value) public {
        context.wallet_address = value;
        this.send(Event.TextEntered, "");
    }
}


abstract contract Transitionable is
    Init_WaitingInputWalletAddress,
    WaitingInputWalletAddress_WalletWasInitialized,
    WalletWasInitialized_WalletWasInitialized,
    WalletWasInitialized_WaitingInputWalletAddress {
    struct Transition {
        Stateable.State from;
        Stateable.State to;
        Event sm_event;
    }

    function init_transitions() public returns(Transition[]) {
        return [
            Init_WaitingInputWalletAddress_transition(),
            WaitingInputWalletAddress_WalletWasInitialized_transition(),
            WaitingInputWalletAddress_WalletWasInitialized_transition(),
            WalletWasInitialized_WalletWasInitialized_transition(),
            WalletWasInitialized_WaitingInputWalletAddress_transition()
        ];
    }

    function transition(Stateable.State from, Stateable.State to, string arg) public {
        Init_WaitingInputWalletAddress_checkAndExecute(from, to, arg);
        WaitingInputWalletAddress_WalletWasInitialized_checkAndExecute(from, to, arg);
        WalletWasInitialized_WalletWasInitialized_checkAndExecute(from, to, arg);
        WalletWasInitialized_WalletWasInitialized_checkAndExecute(from, to, arg);
        WalletWasInitialized_WaitingInputWalletAddress_checkAndExecute(from, to, arg);
    }
}