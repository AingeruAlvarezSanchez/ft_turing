(* ── Cinta (zipper persistente) ───────────────────────────────────────
   El modelo de la cinta y nada mas: leer, escribir, mover la cabeza y
   responder a las consultas del contrato (tape.mli). La ventana de 20 celdas
   que sale en la traza la dibuja quien pinta: la cinta no sabe pintarse, solo
   sabe donde esta la cabeza.

   LA REPRESENTACION ES LO QUE HACE INTERESANTE ESTE MODULO. La cinta son tres
   trozos: lo que hay a la izquierda del cabezal, la celda del cabezal, y lo
   que hay a la derecha. Con eso, escribir o mover es cambiar UN campo en lugar
   de reconstruir la cinta — y eso no es un detalle de estilo: cada paso deja
   una configuracion en la traza, asi que una cinta que se copiase entera en
   cada paso multiplicaria el coste por lo que mide la cinta.

   `left` guarda las celdas MAS CERCANAS al cabezal primero, al REVES que el
   orden de lectura: asi moverse es sacar de una lista y meter en la otra, sin
   recorrer nada. Esa mania no sale del modulo — `to_list` y `left_of` ya
   devuelven el orden de lectura, que es lo que quiere quien pinta. *)

type t = {
  left : Type.symbol list; (* mas cercanas al cabezal primero *)
  head : Type.symbol;
  right : Type.symbol list; (* en orden de lectura *)
  blank : Type.symbol;
}

(* Entrada vacia: no hay celda que leer, asi que el cabezal se queda sobre el
   blanco (que es un simbolo de ESTA cinta, no un '.' escrito a mano). *)
let create ~blank input =
  match List.of_seq (String.to_seq input) with
  | [] -> { left = []; head = blank; right = []; blank }
  | head :: right -> { left = []; head; right; blank }

let read tape = tape.head

let write symbol tape = { tape with head = symbol }

(* La celda que el cabezal deja atras pasa al lado contrario. Si al otro lado
   no habia nada (borde de lo escrito) se materializa el blanco: la cinta es
   infinita en las dos direcciones. *)
let move action tape =
  let behind = tape.head in
  match action with
  | Type.Left -> (
      let head, left =
        match tape.left with
        | [] -> (tape.blank, [])
        | previous :: left -> (previous, left)
      in
      { tape with left; head; right = behind :: tape.right })
  | Type.Right -> (
      let head, right =
        match tape.right with
        | [] -> (tape.blank, [])
        | next :: right -> (next, right)
      in
      { tape with left = behind :: tape.left; head; right })

(* Lo que hace el ejecutor en cada paso: escribir y despues moverse, en ese
   orden (al reves, la maquina leeria la celda equivocada). *)
let apply transition tape =
  tape |> write transition.Type.write |> move transition.Type.action

(* ── consultas (lo que declara tape.mli) ────────────────────────────── *)

(* No es `List.take`: esa esta en el stdlib solo desde versiones nuevas y esto
   tiene que compilar con el OCaml que traiga el evaluador. Mismo comportamiento
   (n <= 0 -> [], n mayor que la lista -> la lista entera). *)
let rec take count list =
  if count <= 0 then []
  else match list with [] -> [] | item :: rest -> item :: take (count - 1) rest

let blank tape = tape.blank

(* `rev_append` en vez de `@`: evita copiar la parte izquierda, que en una cinta
   larga es la mayor. *)
let to_list tape = List.rev_append tape.left (tape.head :: tape.right)

(* Cuantas celdas hay a la izquierda ES la posicion del cabezal: por eso `left`
   se puede guardar al reves sin pagar nada al preguntar. *)
let head_index tape = List.length tape.left

(* Se cogen las celdas al reves (que es como estan) y se da la vuelta: asi el
   coste es lo que se pide, no lo que mide la cinta. Importa porque la traza
   pide 20 celdas por linea, y recorrer la cinta entera ahi convertiria el
   volcado en cuadratico. *)
let left_of count tape = List.rev (take count tape.left)

let right_of count tape = take count tape.right
