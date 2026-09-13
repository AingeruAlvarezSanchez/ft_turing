type symbol = char
type state = string
type action = Left | Right

module StateMap = Map.Make(struct
  type t = state * symbol
  let compare = compare
end)

type transition = {
  read: symbol;
  to_state: string;
  write: symbol;
  action: action;
}

type machine = {
  name: string;
  alphabet: symbol list;
  blank: symbol;
  states: state list;
  initial: state;
  finals: state list;
  transitions: transition StateMap.t;
}