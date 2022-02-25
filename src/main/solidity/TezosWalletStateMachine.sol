pragma ton-solidity >= 0.53.0;

import "./feature/_all.sol";
import "./sm/_all.sol";
import "./wallet/_all.sol";

abstract contract TezosWalletStateMachine is StateMachine,
    InputWalletAddress,
    MainMenu,
    ShowBalance,
    InputSecret,
    MakeTransfer
    {

    function init() internal {
        walletData = WalletData("", 0);
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
    // {MakeTransfer}           MainMenu                    ->  Transfer
    // {Done}                   Transfer                    ->  MainMenu
    function initTransitions() private pure returns(Transition[]) {
        return [
            Transition(Event.Start,                     State.Init,                             State.WaitingInputWalletAddress),
            Transition(Event.Done,                      State.WaitingInputWalletAddress,        State.WaitingSecretInput),
            Transition(Event.Done,                      State.WaitingSecretInput,               State.MainMenu),
            Transition(Event.RequestBalance,            State.MainMenu,                         State.BalanceRequested),
            Transition(Event.Done,                      State.BalanceRequested,                 State.MainMenu),
            Transition(Event.ChangeWalletAddress,       State.MainMenu,                         State.WaitingInputWalletAddress),
            Transition(Event.RequestSecret,             State.MainMenu,                         State.WaitingSecretInput),
            Transition(Event.MakeTransfer,              State.MainMenu,                         State.Transfer),
            Transition(Event.Done,                      State.Transfer,                         State.MainMenu)
        ];
    }

    function transition(State from, State to) internal override {
        if(State.WaitingInputWalletAddress == to) requestAddress();
        if(State.MainMenu == to) showMainMenu();
        if(State.BalanceRequested == to) requestBalance();
        if(State.WaitingSecretInput == to) requestSecret();
        if(State.Transfer == to) inputTransferData();
    }
}
