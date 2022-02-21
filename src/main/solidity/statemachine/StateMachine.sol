pragma ton-solidity >= 0.53.0;

import "./Action.sol";
import "../lib/TezosClient.sol";


abstract contract StateMachine is Contextable, Stateable, Transitionable {

    State current_state;

    mapping(State => mapping(Event => State)) transitions;

    function init() public {
        // init context
        context = init_context();
        // init state
        current_state = init_state();
        // init transitions
        Transition[] _transitions = init_transitions();
        // prepare transitions
        for (uint i = 0; i < _transitions.length; i++) {
            Transition transition = _transitions[i];
            transitions[transition.from][transition.sm_event] = transition.to;
        }
    }

    function send(Event sm_event, string param) public override {
        State to = transitions[current_state][sm_event];
        transition(current_state, to, param);
        current_state = to;
    }
}
