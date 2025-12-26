From Excalead Require Import Excalead Tactics Vector Anchor_lang.

From Excalead.examples.domin8 Require Import state.mod errors constants.

(*
#[derive(Accounts)]
pub struct DepositBet<'info> {
    #[account(
        mut,
        seeds = [GAME_ROUND_SEED],
        bump
    )]
    pub game_round: Account<'info, GameRound>,
    
    /// CHECK: This is the vault PDA that holds game funds
    #[account(
        mut,
        seeds = [VAULT_SEED],
        bump
    )]
    pub vault: UncheckedAccount<'info>,
    
    #[account(mut)]
    pub player: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}
*)
Module DepositBet.
  (* #[derive(Accounts)] *)
  Record t : Set := {
    game_round: GameRound.t;
    vault: UncheckedAccount.t;
    player: Signer.t;
    system_program: System.t;
  }.


  #[export]
  Instance DepositBet_JEncode : JEncode DepositBet.t :=
    fun x => JSON__Object [
      ("game_round", encode x.(game_round));
      ("vault", encode x.(vault));
      ("player", encode x.(player));
      ("system_program", encode x.(system_program))
      ].

  #[export]
  Instance DepositBet_JDecode : JDecode DepositBet.t :=
    fun j => match j with
    | JSON__Object [
      ("game_round", game_round_json);
      ("vault", vault_json);
      ("player", player_json);
      ("system_program", system_program_json)
      ] =>
      decode game_round_json >>= fun game_round =>
      decode vault_json >>= fun vault =>
      decode player_json >>= fun player =>
      decode system_program_json >>= fun system_program =>
      inr {|
        game_round := game_round;
        vault := vault;
        player := player;
        system_program := system_program  |}
    | _ =>
      inl "Failed to decode DepositBet"
    end.
End DepositBet.
Export (hints) DepositBet.

Definition deposit_bet
    (ctx : Context.t DepositBet.t)
    (amount: u64) :
    Result.t GameRound.t :=
  let game_round := ctx.(Context.accounts).(DepositBet.game_round) in
  let player_key := key ctx.(Context.accounts).(DepositBet.player) in
  let? clock := Clock.get in

  require!
    GameRound.can_accept_players game_round with
    "Invalid game status" in

  require!
    amount >=i MIN_BET_LAMPORTS with
    "Bet too small" in

  require!
    Z.of_nat (List.length game_round.(GameRound.players)) <i MAX_PLAYERS with
    "Max Players Reached" in

  let? _ :=
    (* // Transfer SOL to vault *)
    SystemProgram.transfer
      (Context.new
        (to_account_info ctx.(Context.accounts).(DepositBet.system_program))
        ({| SystemProgram.Transfer.from :=
              to_account_info ctx.(Context.accounts).(DepositBet.player);
            SystemProgram.Transfer.to :=
              to_account_info ctx.(Context.accounts).(DepositBet.vault);
        |}))
      amount
  in

  (* // Update game state based on current status *)
  let game_round :=
    match game_round.(GameRound.status) with
    | GameStatus.Idle =>
      (* // First player - transition to Waiting *)
      game_round
        <| GameRound.status := GameStatus.Waiting |>
        <| GameRound.start_timestamp := clock.(Clock.unix_timestamp) |>
        <| GameRound.initial_pot := amount  |>
      (* msg!("Game started by first player"); *)
    | _ =>
      (* // Add to existing pot *)
      game_round
        <| GameRound.initial_pot :=
            game_round.(GameRound.initial_pot) +is amount |>
    end in

    (* // Find existing player or add new one *)
    let game_round :=
      match GameRound.find_player_mut game_round player_key with
      | Some handle =>
        handle (fun existing_player => {|
            (* // Player already exists - add to their bet *)
            PlayerEntry.wallet := existing_player.(PlayerEntry.wallet);
            PlayerEntry.total_bet :=
              existing_player.(PlayerEntry.total_bet) +is amount;
            PlayerEntry.timestamp := clock.(Clock.unix_timestamp)
          |}
          (* msg!("Updated bet for player: {}, new total: {}", player_key, existing_player.total_bet); *)
          )
      | None =>
        (* // New player *)
        let player_entry := {|
          PlayerEntry.wallet := player_key;
          PlayerEntry.total_bet := amount;
          PlayerEntry.timestamp := clock.(Clock.unix_timestamp)
        |} in
        game_round <|
          GameRound.players := player_entry :: game_round.(GameRound.players)
        |>
        (* msg!("New player joined: {}, bet: {}, total players: {}",  *)
        (*      player_key, amount, game_round.players.len()); *)
      end in

    (* msg!("Total pot: {} lamports", game_round.initial_pot); *)

  Result.Ok game_round.

Lemma deposit_bet_is_valid (ctx : Context.t DepositBet.t) (amount : u64)
    (G_game_round : GameRound.Valid.t ctx.(Context.accounts).(DepositBet.game_round)) :
  match deposit_bet ctx amount with
  | Result.Ok (result1) => GameRound.Valid.t result1
  | Result.Err _ => True
  end.
Proof.
  unfold deposit_bet.
  step; step; step; step; step;
    match goal with | H: SystemProgram.transfer _ _ = _ |- _ => clear H end.
  match goal with
  | |- context [ GameRound.find_player_mut ?game_round _ ] =>
    remember game_round as game_round' eqn:HeqGameRound;
    assert (Hgame_round'_length:
        Z.of_nat (Datatypes.length game_round'.(GameRound.players)) < i[MAX_PLAYERS]
    )
  end. {
    subst.
    step; unfold "<i" in *; cbn in *; lia.
  }
  clear HeqGameRound.
  unfold GameRound.find_player_mut.
  match goal with
  | |- context [Vector.zipper_find ?pred' ?vec' ] =>
    set (pred:=pred'); clearbody pred;
    destruct (Vector.zipper_spec pred vec')
  end.
  { (* If GameRound.find_player_mut didn't find the player *)
    rewrite Hresult.
    constructor.
    unfold "<i" in *.
    cbn in *.
    lia.
  }
  { (* If GameRound.find_player_mut did find the player *)
    rewrite Hresult.
    constructor.
    unfold "<i" in *; cbn in *.
    rewrite unzipper_length with (x := x), <- Hunzip.
    lia.
  }
Qed.

(** This funcction takes input that nomally goes into deposit_bet, but in json
  representation, then decodes it, feeds it to deposit_bet, encodes output as
  json and returns it. *)
Definition test_deposit_bet (ctx_input amount_input : json) : Result.t json :=
  match
    decode ctx_input >>= fun ctx_accounts =>
    decode amount_input >>= fun amount =>
    ret (
      let ctx := Context.Build_t _ ctx_accounts in
      let? output := deposit_bet ctx amount in
      Result.Ok (encode output))
  with
  | inr res => res
  | inl s => Result.Err s
  end.
