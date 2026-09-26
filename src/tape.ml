type t = {
  left : Type.symbol list; (* la mas cercana al cabezal primero, al reves del orden de lectura *)
  head : Type.symbol;
  right : Type.symbol list; (* en orden de lectura *)
  blank : Type.symbol;
}

let create ~blank input =
  match List.of_seq (String.to_seq input) with
  | [] -> { left = []; head = blank; right = []; blank }
  | head :: right -> { left = []; head; right; blank }

let read tape = tape.head

let write symbol tape = { tape with head = symbol }

(* La celda que se deja atras pasa al otro lado; si alli no habia nada se
   materializa el blanco: la cinta es infinita por los dos lados. *)
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

let apply transition tape =
  tape |> write transition.Type.write |> move transition.Type.action

(* take a mano: List.take no esta en todas las versiones de OCaml. *)
let rec take count list =
  if count <= 0 then []
  else match list with [] -> [] | item :: rest -> item :: take (count - 1) rest

let blank tape = tape.blank

let to_list tape = List.rev_append tape.left (tape.head :: tape.right)

let head_index tape = List.length tape.left

(* O(count), no O(cinta): la traza pide 20 celdas por linea. *)
let left_of count tape = List.rev (take count tape.left)

let right_of count tape = take count tape.right
