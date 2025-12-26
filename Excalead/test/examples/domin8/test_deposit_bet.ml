(* LICENSE *)


module Lib = Extracted.Lib
module Result = Extracted.Result

let test_deposit_bet (input_amount : int) input_ctx =
  match Extracted.Deposit_bet.test_deposit_bet input_ctx
    (JSON__Number input_amount) with
  | Result.Ok game_round -> Some game_round
  | Result.Err str -> Some (JSON__String str)

let _ = (* Test deposit_bet *)
  let input_obj = failwith "insert input" in
  let input_amount = 42 in
  let output = Extracted.Lib.YojsonRunner.from_string
        ~input:input_obj
        (test_deposit_bet input_amount) in
  Yojson.Basic.pretty_to_string ~std:true output |> print_endline

