(* Definitions in this module will probably be separated between multiple files
   with this library's growth. *)

Require Import Traits Base.

Require Import Excalead.Excalead.

Module IsWritable.
  Inductive t : Set := Yes | No.
End IsWritable.

Module IsSigner.
  Inductive t : Set := Yes | No.
End IsSigner.

Module IsOptional.
  Inductive t : Set := Yes | No.
End IsOptional.

Module Address.
  Inductive t : Set := Constant (s : string) | Any.
End Address.

Module PdaSeed.
  Inductive t : Set :=
  | Const (value : list Z)
  | Arg (path : string)
  | Account (path : string) (account : option string).
End PdaSeed.

Module Pda.
  Inductive t : Set :=
  | No
  | Yes (seeds : list PdaSeed.t) (program : option PdaSeed.t).
End Pda.

Module Account.
  Parameter t : IsWritable.t -> IsSigner.t -> IsOptional.t -> Address.t -> Pda.t -> Set.
End Account.
Export Account.

Module UncheckedAccount.
  Parameter t : Set.

  Parameter ToAccountInfo_UncheckedAccount : ToAccountInfo UncheckedAccount.t.
  #[export] Existing Instance ToAccountInfo_UncheckedAccount.
End UncheckedAccount.
Export UncheckedAccount.

Module Signer.
  Parameter t : Set.

  Parameter lamports : forall (self : Signer.t), u64.

  Parameter Key_Signer : Key Signer.t.
  #[export] Existing Instance Key_Signer.

  Parameter ToAccountInfo_Signer : ToAccountInfo Signer.t.
  #[export] Existing Instance ToAccountInfo_Signer.
End Signer.
Export Signer.

Module System.
  Parameter t : Set.

  Parameter ToAccountInfo_System : ToAccountInfo System.t.
  #[export] Existing Instance ToAccountInfo_System.
End System.
Export System.

Module SystemAccount.
  Parameter t : Set.

  Parameter ToAccountInfo_SystemAccount : ToAccountInfo SystemAccount.t.
  #[export] Existing Instance ToAccountInfo_SystemAccount.
End SystemAccount.
Export SystemAccount.

Module Context.
  Record t {Accounts : Set} : Set := {
    (* program : AccountInfo; *)
    accounts : Accounts;
  }.
  Arguments t : clear implicits.

  Definition new {Accounts : Set} (_ : AccountInfo.t) (accounts : Accounts) :
      Context.t Accounts :=
    Build_t _ accounts.
  (* Parameter new : forall {Accounts : Set}, *)
  (*   AccountInfo.t -> Accounts -> Context.t Accounts. *)
End Context.
Export Context.

Module SystemProgram.
  Module Transfer.
    Record t : Set := {
      from : AccountInfo.t;
      to : AccountInfo.t;
    }.
  End Transfer.

  Parameter transfer : forall {Accounts : Set},
    Context.t Accounts -> u64 -> Result.t unit.
End SystemProgram.

Module Clock.
  Record t : Set := {
    unix_timestamp : i64;
  }.

  Parameter get : Result.t t.
End Clock.

