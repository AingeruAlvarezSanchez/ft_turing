open Yojson.Basic.Util

let to_symbol (s: string): char = 
  if String.length s <> 1 then
    failwith Constant.not_a_character
  else
    s.[0]

let parse_file (fname: string): Type.machine = 
  let json = Yojson.Basic.from_file fname in
  let states = json |> member "states" |> to_list |> List.map to_string in
  let alphabet = json |> member "alphabet" |> to_list |> List.map to_string |> List.map to_symbol in
  {
    name = json |> member "name" |> to_string;
    alphabet;
    blank = (
      let value = json |> member "blank" |> to_string |> to_symbol in
      if not (List.mem value alphabet) then failwith ("[blank] " ^ Constant.not_valid_alphabet)
      else value
    );
    states;
    initial = (
      let value = json |> member "initial" |> to_string in 
      if not (List.mem value states) then failwith ("[initial] " ^ Constant.not_valid_state)
      else value
    );
    finals =  (
      let value = json |> member "finals" |> to_list |> List.map to_string in
      if not (List.for_all (fun elem -> List.mem elem states) value) then failwith ("[finals] " ^ Constant.not_valid_state)
      else value
    );
  }