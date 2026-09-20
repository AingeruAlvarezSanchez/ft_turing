(* El shell del ejecutable: convierte argv en una ACCION, la ejecuta y decide el
   codigo de salida. El formato de lo que se imprime es cosa de Render; aqui solo
   se ordena y se traduce a un numero. *)

type action =
  | Help
  | Run of { description : string; input : string }

let is_help = function "-h" | "--help" -> true | _ -> false

(* Los dos usos validos: `--help` en cualquier posicion, o `descripcion entrada`.
   Todo lo demas es error de uso, con el texto de Constant. Se decide UNA vez, asi
   que el `-h` tiene un solo camino (antes habia dos y uno era inalcanzable). *)
let action_of_arguments (argv : string list) : (action, string) result =
  if List.exists is_help argv then Ok Help
  else
    match argv with
    | [ _; description; input ] -> Ok (Run { description; input })
    | _ :: _ :: _ :: _ -> Error Constant.too_many_args
    | _ -> Error Constant.too_few_args

(* 0 = hubo veredicto (ACCEPTED o BLOCKED: el atasco es un desenlace normal que la
   letra pide informar). 1 = no lo hubo. La letra no pide ningun codigo. *)
let exit_code_of_status = function
  | Executor.Timed_out -> 1
  | Executor.Accepted | Executor.Blocked -> 0

let simulate (machine : Type.machine) (input : string) : int =
  Render.print_header machine;
  let initial = Executor.initial machine ~input in
  let status, final, trace = Executor.run_traced machine initial in
  Render.print_trace trace;
  Render.print_outcome status final;
  exit_code_of_status status

(* La frontera de errores. El parser revienta (`failwith` y las excepciones de
   Yojson), y es aqui donde se convierte en un mensaje; nunca un backtrace. *)
let run (description : string) (input : string) : int =
  if not (Sys.file_exists description) then begin
    Printf.eprintf "%s: %s: no such file\n" Constant.program_name description;
    1
  end
  else if Sys.is_directory description then begin
    Printf.eprintf "%s: %s: is a directory, not a json file\n"
      Constant.program_name description;
    1
  end
  else
    try simulate (Parse.parse_file description input) input with
    | Yojson.Json_error message ->
        Printf.eprintf "%s: %s: invalid json (%s)\n" Constant.program_name
          description message;
        1
    | Yojson.Basic.Util.Type_error (message, _) | Failure message ->
        Printf.eprintf "%s: %s; %s\n" Constant.program_name Constant.error message;
        1

let main (argv : string list) : int =
  match action_of_arguments argv with
  | Error message ->
      Printf.eprintf "%s" message;
      1
  | Ok Help ->
      Print.print_help ();
      0
  | Ok (Run { description; input }) -> run description input
