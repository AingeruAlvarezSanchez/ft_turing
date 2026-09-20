(* ── Contrato de la cinta ─────────────────────────────────────────────
   Este .mli ES la frontera. Todo lo que hay debajo (como se guardan las
   celdas, que la izquierda este al reves, que cruzar el borde materialice
   un blanco) es asunto de tape.ml y no sale de aqui.

   Dos formas de pedir celdas, a proposito:
     - `to_list`  = la cinta ENTERA (O(cinta)). Para el volcado final,
                    que se llama una vez.
     - `left_of` / `right_of` = hasta n celdas a cada lado (O(n)). Para la
                    traza, que pinta UNA LINEA POR PASO: materializar la
                    cinta entera ahi vuelve el volcado cuadratico. *)

type t

val create : blank:Type.symbol -> string -> t

val read : t -> Type.symbol

val write : Type.symbol -> t -> t

val move : Type.action -> t -> t

val apply : Type.transition -> t -> t

(* El blanco de esta cinta (el de su maquina). *)
val blank : t -> Type.symbol

(* La cinta entera, en orden de lectura: de la celda mas lejana por la
   izquierda hasta la mas lejana por la derecha, cabezal incluido.
   O(cinta) — no usar por linea de traza. *)
val to_list : t -> Type.symbol list

(* Posicion del cabezal dentro de `to_list` (0 = primera celda). *)
val head_index : t -> int

(* Hasta `count` celdas a la izquierda / derecha del cabezal, ya en orden de
   lectura (izquierda: de la mas lejana a la mas cercana). O(count). *)
val left_of : int -> t -> Type.symbol list

val right_of : int -> t -> Type.symbol list
