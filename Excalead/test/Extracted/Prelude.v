From Excalead Require Import Excalead Anchor_lang.
From Excalead.examples.domin8.model.instructions Require Import deposit_bet.
Require Extraction.

Require Export ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt.

Require Export ExtrOcamlString.

Extraction Inline set.
Set Extraction Flag 2032.

(* These need to be assigned extract constant, because in formalization
    they are axioms *)
Extract Constant AccountInfo.t => "unit".

Extract Constant UncheckedAccount.t => "unit".
Extract Constant UncheckedAccount.UncheckedAccount_ToAccountInfo => "fun _ -> ()".

Extract Constant System.t => "unit".
Extract Constant System.System_ToAccountInfo => "fun _ -> ()".

Extract Constant Signer.t => "unit".
Extract Constant Signer.Signer_Key => "fun _ -> []".
Extract Constant Signer.Signer_ToAccountInfo => "fun _ -> ()".

Extract Constant SystemProgram.transfer => "fun _ _ -> Result.Ok ()".

Extract Constant Clock.get => "Result.Ok 42".


Set Extraction Output Directory ".".

(* ========================================================================= *)
(* Extract all the tests *)
Separate Extraction deposit_bet.test_deposit_bet.

