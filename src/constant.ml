let name : string = "ft_turing"
let error : string = "Error"

let too_few_args : string = name ^ ": " ^ error ^ "; The program must have at least one argument\n"
let too_many_args : string = name ^ ": " ^ error ^ "; Too many arguments\n"
let unrecognized_opt : string = name ^ ": " ^ error ^ "; Unrecognized option\n"

let help_text : string = "usage: " ^ name ^ " [-h] jsonfile input

positional arguments:
  jsonfile            json description of the machine

  input               input of the machine

optional arguments:
  -h, --help          show this help message and exit\n"