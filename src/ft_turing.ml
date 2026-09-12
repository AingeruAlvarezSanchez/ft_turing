open Constant
open Yojson

let print_help () = Printf.printf "%s" Constant.help_text

let parse_file (fname: string): int = 0


let parse_args (fname: string): int = 
  match fname with
  | "--help" | "-h" -> 
    print_help ();
    0
  | _ -> parse_file fname

let main () =
  match Array.to_list Sys.argv with
  | [] | [_] -> 
    Printf.eprintf "%s" Constant.too_few_args;
    1
  | [_; a2] -> exit (parse_args a2)
  | _ -> 
    Printf.eprintf "%s" Constant.too_many_args;
    1

let () = exit (main ())
