pragma ton-solidity >= 0.53.0;

import "./feature/_all.sol";
import "./sm/_all.sol";
import "./wallet/_all.sol";

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

abstract contract TezosWalletStateMachine is StateMachine,
    InputWalletAddress,
    MainMenu,
    ShowBalance,
    InputSecret,
    InputTargetAddress,
    InputTransferAmount,
    InputTransferFee,
    StartTransfer {

    function init() internal {
        walletData = WalletData("", 0, TezosTransfer("", 0, 0));
        Transition[] _transitions = initTransitions();

        mapping(State => mapping(Event => State)) transitions;

        for (uint i = 0; i < _transitions.length; i++) {
            Transition _transition = _transitions[i];
            transitions[_transition.from][_transition.sm_event] = _transition.to;
        }
        stateMachineContext = StateMachineContext(transitions, State.Init);
        send(Event.Start);
    }

    function initTransitions() private pure returns(Transition[]) {
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

    function transition(State from, State to) internal override {
        if(State.WaitingInputWalletAddress == to) requestInputAddress();
        if(State.WalletWasInitialized == to) showMainMenu();
        if(State.BalanceRequested == to) requestBalance();
        if(State.WaitingSecretInput == to) requestSecret();
        if(State.WaitingInputTargetAddress == to) requestInputTargetAddress();
        if(State.WaitingInputAmount == to) requestInputTransferAmount();
        if(State.WaitingInputFee == to) requestInputTransferFee();
        if(State.WaitingConfirmation == to) requestConfirmation();
    }
}
