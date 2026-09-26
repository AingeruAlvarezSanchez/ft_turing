(* Abstracta: cambiar lo que guarda una configuracion no toca a nadie mas. *)
type configuration

type status =
  | Accepted
  | Blocked
  | Timed_out

val initial : Type.machine -> input:string -> configuration

val run :
  ?max_steps:int -> Type.machine -> configuration -> status * configuration

(* Lo mismo, mas la traza: cinta ANTES de cada paso y regla aplicada. *)
val run_traced :
  ?max_steps:int ->
  Type.machine ->
  configuration ->
  status * configuration * (configuration * Type.transition) list

val state : configuration -> Type.state

val tape : configuration -> Tape.t

val steps : configuration -> int
