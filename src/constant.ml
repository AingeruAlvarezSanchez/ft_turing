let name: string = "ft_turing"
let error: string = "Error"

let read: string = "read"
let write: string = "write"
let to_state: string = "to_state"
let action: string = "action"
let transitions: string = "transitions"
let states: string = "states"
let alphabet: string = "alphabet"
let name: string = "name"
let blank: string = "blank"
let initial: string = "initial"
let finals: string = "finals"

let too_few_args: string = name ^ ": " ^ error ^ "; The program must have at least one argument\n"
let too_many_args: string = name ^ ": " ^ error ^ "; Too many arguments\n"
let unrecognized_opt: string = name ^ ": " ^ error ^ "; Unrecognized option\n"
let not_a_character: string = "must be a character"
let not_valid_alphabet: string = "value is not a valid alphabet character"
let not_valid_state: string = "value is not a valid state"
let not_valid_action: string = "action is not valid"

let decorator: string = "********************************************************************************
*                                                                              *
*                                 unary_sub                                    *
*                                                                              *
********************************************************************************
"

let help_text: string = "usage: " ^ name ^ " [-h] jsonfile input

positional arguments:
  jsonfile            json description of the machine

  input               input of the machine

optional arguments:
  -h, --help          show this help message and exit\n"