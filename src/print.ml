open Type

let print_help () = Printf.printf "%s" Constant.help_text

let print_unary (machine: Type.machine) =
    Printf.printf "%s" Constant.decorator;
    Printf.printf "Name: %s\n" machine.name;
    Printf.printf "Alphabet:\n";
    List.iter (fun m -> Printf.printf " - %c \n" m) machine.alphabet;
    Printf.printf "Blank: %c\n" machine.blank;
    Printf.printf "States:\n";
    List.iter (fun m -> Printf.printf " - %s \n" m) machine.states;
    Printf.printf "Initial: %s\n" machine.initial;
    Printf.printf "Finals:\n";
    List.iter (fun m -> Printf.printf " - %s \n" m) machine.finals;
    Printf.printf "Transitions:\n";
    Type.StateMap.iter
        (fun (state_name, read) (t : Type.transition) ->
            Printf.printf " - (%s, %c) -> (%s, %c, %s)\n"
            state_name read t.to_state t.write
            (match t.action with Type.Left -> "LEFT" | Type.Right -> "RIGHT"))
    machine.transitions