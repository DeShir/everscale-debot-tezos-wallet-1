pragma ton-solidity >= 0.53.0;

import "./feature/_all.sol";
import "./sm/_all.sol";
import "./wallet/_all.sol";

abstract contract TezosWalletStateMachine is StateMachine,
    InputWalletAddress,
    MainMenu,
    ShowBalance,
    InputSecret,
    StartTransfer,
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

    // {Start}                  Init                        ->  WaitingInputWalletAddress
    // {Done}                   WaitingInputWalletAddress   ->  WaitingSecretInput
    // {Done}                   WaitingSecretInput          ->  MainMenu
    // {RequestBalance}         MainMenu                    ->  BalanceRequested
    // {Done}                   BalanceRequested            ->  MainMenu
    // {ChangeWalletAddress}    MainMenu                    ->  WaitingInputWalletAddress
    // {RequestSecret}          MainMenu                    ->  WaitingSecretInput
    // {StartTransfer}          MainMenu                    ->  ProvideTransferData
    // {Done}                   ProvideTransferData         ->  ConfirmTransfer
    // {Done}                   ConfirmTransfer             ->  ConfirmTransfer
    function initTransitions() private pure returns(Transition[]) {
        return [
            Transition(Event.Start,                     State.Init,                             State.WaitingInputWalletAddress),
            Transition(Event.Done,                      State.WaitingInputWalletAddress,        State.WaitingSecretInput),
            Transition(Event.Done,                      State.WaitingSecretInput,               State.MainMenu),
            Transition(Event.RequestBalance,            State.MainMenu,                         State.BalanceRequested),
            Transition(Event.Done,                      State.BalanceRequested,                 State.MainMenu),
            Transition(Event.ChangeWalletAddress,       State.MainMenu,                         State.WaitingInputWalletAddress),
            Transition(Event.RequestSecret,             State.MainMenu,                         State.WaitingSecretInput),
            Transition(Event.StartTransfer,             State.MainMenu,                         State.ProvideTransferData),
            Transition(Event.Done,                      State.ProvideTransferData,              State.ConfirmTransfer),
            Transition(Event.Done,                      State.ConfirmTransfer,                  State.MainMenu)
        ];
    }

    function transition(State from, State to) internal override {
        if(State.WaitingInputWalletAddress == to) requestAddress();
        if(State.MainMenu == to) showMainMenu();
        if(State.BalanceRequested == to) requestBalance();
        if(State.WaitingSecretInput == to) requestSecret();
        if(State.ProvideTransferData == to) inputTransferData();
        if(State.ConfirmTransfer == to) requestConfirmation();
    }
}
