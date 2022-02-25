pragma ton-solidity >= 0.53.0;

import "./feature/_all.sol";
import "./sm/_all.sol";
import "./wallet/_all.sol";

// {Start}                  Init                        ->  WaitingInputWalletAddress
// {Done}                   WaitingInputWalletAddress   ->  WaitingSecretInput
// {Done}                   WaitingSecretInput          ->  WalletWasInitialized
// {RequestBalance}         WalletWasInitialized        ->  BalanceRequested
// {Done}                   BalanceRequested            ->  WalletWasInitialized
// {ChangeWalletAddress}    WalletWasInitialized        ->  WaitingInputWalletAddress
// {RequestSecret}          WalletWasInitialized        ->  WaitingSecretInput
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
    ConfirmTransfer {

    function init() internal {
        walletData = WalletData("", 0, TezosTransfer("", 0, 0));
        Transition[] arrTransitions = initTransitions();

        mapping(State => mapping(Event => State)) transitions;

        for (uint i = 0; i < arrTransitions.length; i++) {
            Transition transition = arrTransitions[i];
            transitions[transition.from][transition.smEvent] = transition.to;
        }
        stateMachineContext = StateMachineContext(transitions, State.Init);
        send(Event.Start);
    }

    function initTransitions() private pure returns(Transition[]) {
        return [
            Transition(Event.Start,                     State.Init,                             State.WaitingInputWalletAddress),
            Transition(Event.Done,                      State.WaitingInputWalletAddress,        State.WaitingSecretInput),
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
        if(State.WaitingInputWalletAddress == to) requestAddress();
        if(State.WalletWasInitialized == to) showMainMenu();
        if(State.BalanceRequested == to) requestBalance();
        if(State.WaitingSecretInput == to) requestSecret();
        if(State.WaitingInputTargetAddress == to) requestDestinationAddress();
        if(State.WaitingInputAmount == to) requestTransferAmount();
        if(State.WaitingInputFee == to) requestTransferFee();
        if(State.WaitingConfirmation == to) requestConfirmation();
    }
}
