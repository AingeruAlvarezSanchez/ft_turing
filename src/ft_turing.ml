open Constant
open Type
open Yojson
open Yojson.Basic.Util
open Parse

let print_help () = Printf.printf "%s" Constant.help_text

let execute_args (fname: string): int = 
  match fname with
  | "--help" | "-h" -> 
    print_help ();
    0
  | _ -> 
    try
      let machine = parse_file fname in
      Printf.printf "name: %s\n" machine.name;
      Printf.printf "alphabet:\n";
      List.iter (fun m -> Printf.printf " - %c \n" m) machine.alphabet;
      Printf.printf "blank: %c\n" machine.blank;
      Printf.printf "states:\n";
      List.iter (fun m -> Printf.printf " - %s \n" m) machine.states;
      Printf.printf "initial: %s\n" machine.initial;
      Printf.printf "finals:\n";
      List.iter (fun m -> Printf.printf " - %s \n" m) machine.finals;
      Type.StateMap.iter
        (fun (state_name, read) (t : Type.transition) ->
          Printf.printf "(%s, %c) -> (%s, %c, %s)\n"
          state_name read t.to_state t.write
        (match t.action with Type.Left -> "LEFT" | Type.Right -> "RIGHT"))
      machine.transitions;
      0
    with
    | Type_error (msg, _) | Failure msg ->
        Printf.eprintf "%s: %s; %s\n" Constant.name Constant.error msg;
        1

let main () =
  match Array.to_list Sys.argv with
  | [] | [_] -> 
    Printf.eprintf "%s" Constant.too_few_args;
    1
  | [_; a2] -> exit (execute_args a2)
  | _ -> 
    Printf.eprintf "%s" Constant.too_many_args;
    1

let () = exit (main ())
