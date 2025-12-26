Require Import Excalead Anchor_lang.
Require Export Extraction.

Require Export ExtrOcamlBasic ExtrOcamlNatInt ExtrOcamlZInt.

Require Export ExtrOcamlString.

(* ========================================================================= *)
(* Axiom Extractions *)

Extraction Inline set.
Set Extraction Flag 2032.

Extract Constant AccountInfo.t => "unit".
Extract Constant UncheckedAccount.t => "unit".
Extract Constant UncheckedAccount.UncheckedAccount_ToAccountInfo => "fun _ => ()".
Extract Constant System.t => "unit".
Extract Constant System.System_ToAccountInfo => "fun _ => ()".
Extract Constant Signer.t => "unit".
Extract Constant Signer.Signer_Key => "fun _ => ()".
Extract Constant Signer.Signer_ToAccountInfo => "fun _ => ()".
Extract Constant SystemProgram.transfer => "fun _ _ => Result.Ok ()".
Extract Constant Clock.get => "Result.Ok ()".
Extract Constant Context.new => "fun _ accounts => Result.Ok accounts".


