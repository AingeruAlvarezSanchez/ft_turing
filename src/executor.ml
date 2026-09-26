type configuration = {
  state : Type.state;
  tape : Tape.t;
  steps : int;
}

type status =
  | Accepted
  | Blocked
  | Timed_out

(* La regla viaja con el paso: el write y la action no se recuperan de la
   configuracion siguiente. *)
type step_result =
  | Stepped of configuration * Type.transition
  | Halted of status * configuration

let is_final machine state = List.mem state machine.Type.finals

let step machine configuration =
  if is_final machine configuration.state then Halted (Accepted, configuration)
  else
    let key = (configuration.state, Tape.read configuration.tape) in
    match Type.StateMap.find_opt key machine.Type.transitions with
    | None -> Halted (Blocked, configuration)
    | Some transition ->
        let next =
          {
            state = transition.Type.to_state;
            tape = Tape.apply transition configuration.tape;
            steps = configuration.steps + 1;
          }
        in
        Stepped (next, transition)

let initial machine ~input =
  {
    state = machine.Type.initial;
    tape = Tape.create ~blank:machine.Type.blank input;
    steps = 0;
  }

let state configuration = configuration.state
let tape configuration = configuration.tape
let steps configuration = configuration.steps

(* Recursivo de cola, y el acumulador lo pone quien llama: run no retiene traza. *)
let rec fold_steps ?(max_steps = 100_000) machine configuration ~init ~f =
  if configuration.steps >= max_steps then (Timed_out, configuration, init)
  else
    match step machine configuration with
    | Halted (status, final) -> (status, final, init)
    | Stepped (next, transition) ->
        fold_steps ~max_steps machine next
          ~init:(f init configuration transition) ~f

let run ?(max_steps = 100_000) machine configuration =
  let status, final, () =
    fold_steps ~max_steps machine configuration ~init:() ~f:(fun () _ _ -> ())
  in
  (status, final)

let run_traced ?(max_steps = 100_000) machine configuration =
  let status, final, reversed =
    fold_steps ~max_steps machine configuration ~init:[]
      ~f:(fun accumulated configuration transition ->
        (configuration, transition) :: accumulated)
  in
  (status, final, List.rev reversed)
