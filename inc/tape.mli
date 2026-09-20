(* Lo de dentro (izquierda al reves, blancos materializados) no sale de aqui. *)
type t

val create : blank:Type.symbol -> string -> t

val read : t -> Type.symbol

val write : Type.symbol -> t -> t

val move : Type.action -> t -> t

val apply : Type.transition -> t -> t

val blank : t -> Type.symbol

val to_list : t -> Type.symbol list

val head_index : t -> int

(* Hasta `count` celdas a cada lado, ya en orden de lectura. *)
val left_of : int -> t -> Type.symbol list

val right_of : int -> t -> Type.symbol list
