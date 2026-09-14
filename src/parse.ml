open Yojson.Basic.Util

let to_symbol (s: string): char = 
  if String.length s <> 1 then
    failwith Constant.not_a_character
  else
    s.[0]

let to_action (s: string): Type.action =
  match s with
  | "LEFT" -> Type.Left
  | "RIGHT" -> Type.Right
  | s -> failwith (Constant.not_valid_action ^ s)

let parse_transition (states: Type.state list) (alphabet: Type.symbol list) (t: Yojson.Basic.t): Type.transition =
  {
    read = (
      let value = t |> member Constant.read |> to_string |> to_symbol in
      if not (List.mem value alphabet) then failwith ("[read] " ^ Constant.not_valid_alphabet)
      else value
    );
    write = (
      let value = t |> member Constant.write |> to_string |> to_symbol in
      if not (List.mem value alphabet) then failwith ("[write] " ^ Constant.not_valid_alphabet)
      else value
    );
    to_state = (
      let value = t |> member Constant.to_state |> to_string in
      if not (List.mem value states) then failwith ("[to_state] " ^ Constant.not_valid_state)
      else value
    );
    action = t |> member Constant.action |> to_string |> to_action;
  }

(* 
  For the sake of simplicity, I've decided to briefly explain what this function does in a visual way:

  1. Take the member "transitions" from the JSON and transform it to an object (to_assoc)
  2. use the List.fold_left which works as an accumulator function iterating all over the list, args are;
    1 - fun accumulator tuple
    2 - Initial accumulator value
    3 - the list to apply it to.

  The outer fold_left operates over the following args:
    1 - fun map (state_name(which is the name of the transition e.g. "scanright"), 
                 transitions_json(which is the content of each state e.g 
                  [
                    { "read" : "1", "to_state": "subone", "write": "=", "action": "LEFT"},
                    { "read" : "-", "to_state": "HALT" , "write": ".", "action": "LEFT"}
                  ]))
    2 - Type.StateMap.empty
    3 - the whole content of transitions as a list of tuples, e.g 
        [...
        ("eraseone", [
            { "read" : "1", "to_state": "subone", "write": "=", "action": "LEFT"},
            { "read" : "-", "to_state": "HALT" , "write": ".", "action": "LEFT"}
        ]);
        ("subone", [
            { "read" : "1", "to_state": "subone", "write": "1", "action": "LEFT"},
            { "read" : "-", "to_state": "skip" , "write": "-", "action": "LEFT"}
        ])
        ...]

    3. Then, it calls an inner fold_left to add the content of each state to the "transitions" map. 
       It works in the same way, but iterates over each inner transition (the content of each state_name)
*)
let parse_transitions (states: Type.state list) (alphabet: Type.symbol list) (json: Yojson.Basic.t): Type.transition Type.StateMap.t =
  json |> member Constant.transitions |> to_assoc
  |> List.fold_left
       (fun map (state_name, transitions_json) ->
          transitions_json |> to_list |> List.map (parse_transition states alphabet)
          |> List.fold_left
               (fun map (t : Type.transition) ->
                  Type.StateMap.add (state_name, t.read) t map)
               map)
       Type.StateMap.empty

let parse_file (fname: string): Type.machine = 
  let json = Yojson.Basic.from_file fname in
  let states = json |> member Constant.states |> to_list |> List.map to_string in
  let alphabet = json |> member Constant.alphabet |> to_list |> List.map to_string |> List.map to_symbol in
  {
    name = json |> member Constant.name |> to_string;
    alphabet;
    blank = (
      let value = json |> member Constant.blank |> to_string |> to_symbol in
      if not (List.mem value alphabet) then failwith ("[blank] " ^ Constant.not_valid_alphabet)
      else value
    );
    states;
    initial = (
      let value = json |> member Constant.initial |> to_string in 
      if not (List.mem value states) then failwith ("[initial] " ^ Constant.not_valid_state)
      else value
    );
    finals =  (
      let value = json |> member Constant.finals |> to_list |> List.map to_string in
      if not (List.for_all (fun elem -> List.mem elem states) value) then failwith ("[finals] " ^ Constant.not_valid_state)
      else value
    );
    transitions = parse_transitions states alphabet json;
  }