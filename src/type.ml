type symbol = char
type state = string

type machine = {
  name: string;
  alphabet: symbol list;
  blank: symbol;
  states: state list;
  initial: state;
  finals: state list;
}