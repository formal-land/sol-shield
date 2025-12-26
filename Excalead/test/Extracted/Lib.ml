(* LICENSE *)

open Yojson
type json = JSON.json

module String = Stdlib.String
module List = Stdlib.List

module Conversion = struct
  let string_of_char_list (lst : char list) : string =
    String.of_seq (List.to_seq lst)

  let char_list_of_string (str : string) : char list =
    List.of_seq (String.to_seq str)

  let rec from_coq (obj : json) : Basic.t =
    match obj with
    | JSON__True -> `Bool true
    | JSON__False -> `Bool false
    | JSON__Object lst -> `Assoc (from_coq_object lst)
    | JSON__Array lst -> `List (from_coq_array lst)
    | JSON__String str -> `String (string_of_char_list str)
    | JSON__Number int -> `Int int
    | JSON__Null -> `Null

  and from_coq_object (args : (char list * json) list) =
    List.map (fun (str, obj) ->
      (string_of_char_list str, from_coq obj)) args

  and from_coq_array (args : json list) : Basic.t list =
    List.map from_coq args

  (** Converts Ocaml's representation to Coq's representation.
      Fails if object is representing Float, filters out every occurence of
      float in object. *)
  let rec to_coq (obj : Basic.t) : json option =
    match obj with
    | `Assoc lst  -> Some (JSON__Object (to_coq_object lst))
    | `Bool true  -> Some JSON__True
    | `Bool false -> Some JSON__False
    | `Null       -> Some JSON__Null
    | `List lst   -> Some (JSON__Array (to_coq_array lst))
    | `Float _    -> None
    | `String str -> Some (JSON__String (char_list_of_string str))
    | `Int num    -> Some (JSON__Number num)

  and to_coq_object (args : (string * Basic.t) list)
      : (char list * json) list =
    List.filter_map (fun (str, obj) ->
      Option.bind (to_coq obj) (fun obj ->
      Some (char_list_of_string str, obj))) args

  and to_coq_array (lst : Basic.t list) : json list =
    List.filter_map to_coq lst
end


module YojsonRunner = struct

  let ( let+ ) (a : 'a option * string) (f : 'a -> 'b) : 'b option =
    match a with
    | Some a, _ -> Some (f a)
    | None, msg -> print_endline msg; None

  let ( let* ) (a : 'a option * string) (f : 'a -> 'b option) : 'b option =
    match a with
    | Some a, _ -> f a
    | None, msg -> print_endline msg; None


  let handle_runner (input : Basic.t) (f : json -> json option) =
    let* obj = (Conversion.to_coq input, "Error: Object was a float") in
    f obj |> Option.map Conversion.from_coq

  let unwrap msg = function
      | Some res -> res
      | None     -> failwith msg

  let from_file ~input_filename (f : json -> json option) : Basic.t =
    let input = Yojson.Basic.from_file input_filename in
    handle_runner input f |> unwrap "Function f failed"

  let from_string ~(input : string) (f : json -> json option) : Basic.t =
    let input = Yojson.Basic.from_string input in
    handle_runner input f |> unwrap "Function f failed"

end
