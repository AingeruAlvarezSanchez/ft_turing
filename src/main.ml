(* El ejecutable no tiene logica: pasa argv al shell y devuelve su codigo. *)
let () = exit (Cli.main (Array.to_list Sys.argv))
