pragma ton-solidity >= 0.53.0;

enum Event {Start, Done, RequestBalance, ChangeWalletAddress, RequestSecret, StartTransaction}
enum State {Init, WaitingInputWalletAddress, WalletWasInitialized, BalanceRequested, WaitingSecretInput,
    WaitingInputTargetAddress, WaitingInputAmount, WaitingInputFee, WaitingConfirmation}

struct StateMachineContext {
    mapping(State => mapping(Event => State)) transitions;
    State currentState;
}

struct Transition {
    Event sm_event;
    State from;
    State to;
}

abstract contract StateMachine {
    StateMachineContext internal stateMachineContext;

    function transition(State from, State to) internal virtual { }

    function send(Event _event) internal {
        State to = stateMachineContext.transitions[stateMachineContext.currentState][_event];
        transition(stateMachineContext.currentState, to);
        stateMachineContext.currentState = to;
    }
}
