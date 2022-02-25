pragma ton-solidity >= 0.53.0;

enum Event {Start, Done, RequestBalance, ChangeWalletAddress, RequestSecret, MakeTransfer}
enum State {Init, WaitingInputWalletAddress, MainMenu, BalanceRequested, WaitingSecretInput, Transfer}

struct StateMachineContext {
    mapping(State => mapping(Event => State)) transitions;
    State currentState;
}

struct Transition {
    Event smEvent;
    State from;
    State to;
}

abstract contract StateMachine {
    StateMachineContext internal stateMachineContext;

    function transition(State from, State to) internal virtual { }

    function send(Event smEvent) internal {
        State to = stateMachineContext.transitions[stateMachineContext.currentState][smEvent];
        transition(stateMachineContext.currentState, to);
        stateMachineContext.currentState = to;
    }
}
