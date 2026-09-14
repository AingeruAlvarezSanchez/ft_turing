open Constant
open Type
open Yojson
open Yojson.Basic.Util
open Parse
open Print

let execute_args (fname: string) (input: string): int =
  match fname with
  | "--help" | "-h" -> 
    Print.print_help ();
    0
  | _ -> 
    try
      let machine = parse_file fname input in
      Print.print_unary machine;
      0
    with
    | Type_error (msg, _) | Failure msg ->
        Printf.eprintf "%s: %s; %s\n" Constant.name Constant.error msg;
        1

let main () =
  match Array.to_list Sys.argv with
  | [] | [_] | [_; _] ->
    Printf.eprintf "%s" Constant.too_few_args;
    1
  | [_; a2; a3] -> exit (execute_args a2 a3)
  | _ -> 
    Printf.eprintf "%s" Constant.too_many_args;
    1

let () = exit (main ())
