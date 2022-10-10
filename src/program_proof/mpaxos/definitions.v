From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv Require mpaxos.
From Perennial.program_proof.grove_shared Require Import urpc_proof urpc_spec.
From Perennial.goose_lang.lib Require Import waitgroup.
From iris.base_logic Require Export lib.ghost_var mono_nat.
From iris.algebra Require Import dfrac_agree mono_list.
From Perennial.goose_lang Require Import crash_borrow.
From Perennial.program_proof Require Import marshal_stateless_proof.
From Perennial.program_proof.mpaxos Require Export ghost_proof marshal_proof.

Section definitions.

Record MPRecord :=
  {
    mp_OpType : Type ;
    mp_has_op_encoding : list u8 → mp_OpType → Prop ;
    mp_next_state : list u8 → mp_OpType → list u8 ;
    mp_compute_reply : list u8 → mp_OpType → list u8 ;
  }.

Context {mp_record:MPRecord}.
Notation OpType := (mp_OpType mp_record).
Notation has_op_encoding := (mp_has_op_encoding mp_record).
Notation next_state := (mp_next_state mp_record).
Notation compute_reply := (mp_compute_reply mp_record).

Definition client_logR := dfrac_agreeR (leibnizO (list u8)).

Class mpG Σ := {
    mp_ghostG :> mp_ghostG (EntryType:=(list u8 * (list u8 → iProp Σ))%type) Σ ;
    mp_urpcG :> urpcregG Σ ;
    mp_wgG :> waitgroupG Σ ; (* for apply proof *)
    mp_logG :> inG Σ client_logR;
    mp_apply_escrow_tok :> ghost_varG Σ unit ;
}.

Context `{!heapGS Σ}.
Context `{!mpG Σ}.

Definition own_state γ ς := own γ (to_dfrac_agree (DfracOwn (1/2)) (ς : (leibnizO (list u8)))).

(* RPC specs *)

(* Notation OpType := (mp_OpType mp_record). *)

Context (conf:list mp_server_names).

Definition applyAsFollower_core_spec γ γsrv args σ Q (Φ : u64 -> iProp Σ) : iProp Σ :=
  ("%Hσ_index" ∷ ⌜length σ = (int.nat args.(applyAsFollowerArgs.nextIndex) + 1)%nat⌝ ∗
   "%Hghost_op_σ" ∷ ⌜last σ = Some (args.(applyAsFollowerArgs.state), Q)⌝ ∗
   "%Hno_overflow" ∷ ⌜int.nat args.(applyAsFollowerArgs.nextIndex) < int.nat (word.add args.(applyAsFollowerArgs.nextIndex) 1)⌝ ∗
   "#Hprop_lb" ∷ is_proposal_lb γ args.(applyAsFollowerArgs.epoch) σ ∗
   "#Hprop_facts" ∷ is_proposal_facts conf γ args.(applyAsFollowerArgs.epoch) σ ∗
   "HΨ" ∷ ((is_accepted_lb γsrv args.(applyAsFollowerArgs.epoch) σ -∗ Φ (U64 0)) ∧
           (∀ (err:u64), ⌜err ≠ 0⌝ -∗ Φ err))
    )%I
.

Program Definition applyAsFollowerSpec_spec γ γsrv :=
  λ (encoded_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ Q,
    ⌜applyAsFollowerArgs.has_encoding encoded_args args⌝ ∗
    applyAsFollower_core_spec γ γsrv args σ Q (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
    )%I
.
Next Obligation.
  rewrite /applyAsFollower_core_spec.
  solve_proper.
Defined.

(* TODO: copied from pb_definitions.v *)
Definition appN := mpN .@ "app".
Definition escrowN := mpN .@ "escrow".

Definition get_state (σ:list (list u8 * (list u8 → iProp Σ))) := default [] (last (fst <$> σ)).

Definition is_inv γlog γsys :=
  inv appN (∃ log,
        own_state γlog (get_state log) ∗
        own_ghost γsys log ∗
        □(
          (* XXX: this is a bit different from pb_definitions.v *)
          (* This says that for all (log'prefix ++ [lastEnt]) ⪯ log,
             lastEnt.Q (state of log'prefix) is true.
           *)
          ∀ log' log'prefix lastEnt, ⌜prefix log' log⌝ -∗
                ⌜log' = log'prefix ++ [lastEnt]⌝ -∗
                (lastEnt.2 (get_state log'prefix))
        )
      ).

Definition apply_core_spec γ γlog op enc_op :=
  λ (Φ : applyReply.C -> iPropO Σ) ,
  (
  ⌜has_op_encoding enc_op op⌝ ∗
  is_inv γlog γ ∗
  □(|={⊤∖↑mpN,∅}=> ∃ ς, own_state γlog ς ∗ (own_state γlog (next_state ς op) ={∅,⊤∖↑mpN}=∗
            Φ (applyReply.mkC 0 (compute_reply ς op))
  )) ∗
  □(∀ (err:u64) ret, ⌜err ≠ 0⌝ -∗ Φ (applyReply.mkC err ret))
  )%I
.

(* End RPC specs *)

Definition is_mpaxos_host : (u64 -> mp_system_names -> mp_server_names -> iPropO Σ).
Admitted.

Global Instance is_mpaxos_host_pers host γ γsrv: Persistent (is_mpaxos_host host γ γsrv).
Proof.
Admitted.

Definition is_singleClerk (ck:loc) γ γsrv : iProp Σ :=
  ∃ (cl:loc) srv,
  "#Hcl" ∷ readonly (ck ↦[mpaxos.Clerk :: "cl"] #cl) ∗
  "#Hcl_rpc"  ∷ is_uRPCClient cl srv ∗
  "#Hsrv" ∷ is_mpaxos_host srv γ γsrv
.

(* End clerk specs *)

(* Server-side definitions *)

Definition is_applyFn (applyFn:val) : iProp Σ :=
  ∀ op_sl state_sl (state:list u8) (op_bytes:list u8) op,
  {{{
        ⌜has_op_encoding op_bytes op⌝ ∗
        readonly (is_slice_small op_sl byteT 1 op_bytes) ∗
        readonly (is_slice_small state_sl byteT 1 state)
  }}}
    applyFn (slice_val state_sl) (slice_val op_sl)
  {{{
        newstate_sl reply_sl,
        RET (slice_val newstate_sl, slice_val reply_sl);
        readonly (is_slice_small newstate_sl byteT 1 (next_state state op)) ∗
        is_slice_small reply_sl byteT 1 (compute_reply state op)
  }}}
.

(* Hides the ghost part of the log; this is suitable for exposing as part of
   interfaces for users of the library.
   . *)
Definition own_Server (s:loc) γ γsrv : iProp Σ :=
  ∃ st (isLeader:bool) (clerks_sl:Slice.t)
    state_sl applyFn clerks,
    let nextIndex := U64 (length st.(mp_log)) in
    let state := (default [] (last (fst <$> st.(mp_log)))) in
  (* physical *)
  "Hepoch" ∷ s ↦[mpaxos.Server :: "epoch"] #(st.(mp_epoch)) ∗
  "HnextIndex" ∷ s ↦[mpaxos.Server :: "nextIndex"] #nextIndex ∗
  "HisLeader" ∷ s ↦[mpaxos.Server :: "isLeader"] #isLeader ∗
  "Hclerks" ∷ s ↦[mpaxos.Server :: "clerks"] (slice_val clerks_sl) ∗
  "Hstate" ∷ s ↦[mpaxos.Server :: "state"] (slice_val state_sl) ∗
  "#Hstate_sl" ∷ readonly (is_slice_small state_sl byteT 1 state) ∗
  "HapplyFn" ∷ s ↦[mpaxos.Server :: "applyFn"] applyFn ∗
  "%HnextIndex_nooverflow" ∷ ⌜length st.(mp_log) = int.nat (length st.(mp_log))⌝ ∗

  (* clerks *)
  "%Hconf_clerk_len" ∷ ⌜length clerks = length (conf)⌝ ∗
  "#Hclerks_sl" ∷ readonly (is_slice_small clerks_sl ptrT 1 clerks) ∗
  "#Hclerks_rpc" ∷ ([∗ list] ck ; γsrv' ∈ clerks ; conf, is_singleClerk ck γ γsrv') ∗

  (* applyFn callback spec *)
  "#HisApplyFn" ∷ is_applyFn applyFn ∗

  (* ghost-state *)
  "Hghost" ∷ own_replica_ghost conf γ γsrv st ∗
  "#Hinv" ∷ sys_inv conf γ ∗

  (* leader-only *)
  "HleaderOnly" ∷ (if isLeader then own_leader_ghost conf γ γsrv st else True) ∗
  "%HaccEpochEq" ∷ ⌜if isLeader then st.(mp_acceptedEpoch) = st.(mp_epoch) else True⌝
.

Definition is_Server (s:loc) γ γsrv : iProp Σ :=
  ∃ (mu:val),
  "#Hmu" ∷ readonly (s ↦[mpaxos.Server :: "mu"] mu) ∗
  "#HmuInv" ∷ is_lock mpN mu (own_Server s γ γsrv)
  (* "#Hsys_inv" ∷ sys_inv γ *).

Lemma wp_singleClerk__applyAsFollower ck γ γsrv σ Q args_ptr args reply_ptr init_reply :
  {{{
        "#His_ck" ∷ is_singleClerk ck γ γsrv ∗
        "Hargs" ∷ applyAsFollowerArgs.own args_ptr args ∗
        "Hargs" ∷ applyAsFollowerReply.own reply_ptr init_reply 1 ∗

        "%Hσ_index" ∷ ⌜length σ = (int.nat args.(applyAsFollowerArgs.nextIndex) + 1)%nat⌝ ∗
        "%Hghost_op_σ" ∷ ⌜last σ = Some (args.(applyAsFollowerArgs.state), Q)⌝ ∗
        "%Hno_overflow" ∷ ⌜int.nat args.(applyAsFollowerArgs.nextIndex) < int.nat (word.add args.(applyAsFollowerArgs.nextIndex) 1)⌝ ∗
        "#Hprop_lb" ∷ is_proposal_lb γ args.(applyAsFollowerArgs.epoch) σ ∗
        "#Hprop_facts" ∷ is_proposal_facts conf γ args.(applyAsFollowerArgs.epoch) σ
  }}}
    singleClerk__applyAsFollower #ck #args_ptr #reply_ptr
  {{{
        reply, RET #(); applyAsFollowerReply.own reply_ptr reply 1 ∗
                                                 □if (decide (reply.(applyAsFollowerReply.err) = (U64 0))) then
                                                   is_accepted_lb γsrv args.(applyAsFollowerArgs.epoch) σ
                                                 else
                                                   True
  }}}.
Proof.
Admitted.

End definitions.