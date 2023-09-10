From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv.simplepb.apps Require Import closed.

From Perennial.goose_lang Require adequacy dist_adequacy.
From Perennial.goose_lang.ffi Require grove_ffi_adequacy.
From Perennial.program_logic Require dist_lang.

From Perennial.program_proof.bank Require Export bank_proof.
From Perennial.program_proof.lock Require Export lock_proof.
From Perennial.program_proof.simplepb Require Import pb_init_proof pb_definitions.
From Perennial.program_proof.simplepb Require Import kv_proof config_proof.
From Perennial.program_proof.simplepb.simplelog Require Import proof.
From Perennial.program_proof.simplepb.apps Require Import clerkpool_proof.
From Perennial.program_proof.grove_shared Require Import urpc_proof.
From Perennial.goose_lang Require Import crash_borrow crash_modality.
From Perennial.goose_lang Require Import recovery_lifting.

Section closed_wpcs.

Context `{!heapGS Σ}.
Context `{!ekvG Σ}.

Lemma wpc_kv_replica_main γ γsrv Φc fname me configHost data :
  ((∃ data' : list u8, fname f↦data' ∗ ▷ kv_crash_resources γ γsrv data') -∗
    Φc) -∗
  ("#Hconf" ∷ is_kv_config_hosts [configHost] γ ∗
   "#Hhost" ∷ is_kv_replica_host me γ γsrv ∗
   "Hfile" ∷ fname f↦ data ∗
   "Hcrash" ∷ kv_crash_resources γ γsrv data
  ) -∗
  WPC kv_replica_main #(LitString fname) #me #configHost @ ⊤
  {{ _, True }}
  {{ Φc }}
.
Proof.
  iIntros "HΦc H". iNamed "H".

  unfold kv_replica_main.
  wpc_call.
  { iApply "HΦc". iExists _. iFrame. }

  iCache with "HΦc Hfile Hcrash".
  { iApply "HΦc". iExists _. iFrame. }
  wpc_bind (Primitive2 _ _ _).
  wpc_frame.
  iApply wp_crash_borrow_generate_pre.
  { done. }
  wp_apply (wp_ref_of_zero).
  { done. }
  iIntros (?) "Hl".
  iIntros "Hpreborrow".
  iNamed 1.
  wpc_pures.
  wpc_bind (store_ty _ _).
  wpc_frame.
  wp_store.
  iModIntro.
  iNamed 1.

  iApply wpc_cfupd.
  wpc_apply (wpc_crash_borrow_inits with "Hpreborrow [Hfile Hcrash] []").
  { iAccu. }
  {
    iModIntro.
    instantiate (1:=(|C={⊤}=> ∃ data', fname f↦ data' ∗ ▷ kv_crash_resources γ γsrv data')).
    iIntros "[H1 H2]".
    iModIntro.
    iExists _.
    iFrame.
  }
  iIntros "Hfile_ctx".
  wpc_apply (wpc_crash_mono _ _ _ _ _ (True%I) with "[HΦc]").
  { iIntros "_".
    iIntros "H".
    iMod "H".
    iModIntro.
    iApply "HΦc".
    done. }
  iApply wp_wpc.
  wp_pures.
  wp_apply wp_NewSlice.
  iIntros (?) "Hsl".
  wp_apply wp_ref_to; first by val_ty.
  iIntros (?) "HconfigHosts".
  wp_pures.
  wp_load. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl".
  wp_store. wp_load.
  iDestruct (own_slice_to_small with "Hsl") as "Hsl".
  iMod (readonly_alloc_1 with "Hsl") as "#Hsl".

  wp_apply (wp_Start with "[$Hfile_ctx]").
  { iFrame "#". }
  wp_pures.
  done.
Qed.


Definition dconfigHost : u64 := (U64 11).
Definition dconfigHostPaxos : u64 := (U64 12).
Definition dr1Host: u64 := (U64 1).
Definition dr2Host: u64 := (U64 2).

Definition lconfigHost : u64 := (U64 111).
Definition lconfigHostPaxos : u64 := (U64 112).
Definition lr1Host: u64 := (U64 101).
Definition lr2Host: u64 := (U64 102).

Lemma wp_mk_dconfig_hosts :
  {{{ True }}}
    mk_dconfig_hosts #()
  {{{ sl, RET (slice_val sl); readonly (own_slice_small sl uint64T 1 [ dconfigHost ]) }}}
.
  iIntros (?) "_ HΦ".
  wp_lam. wp_apply (wp_NewSlice).
  iIntros (?) "Hsl". wp_apply wp_ref_to; first by val_ty.
  iIntros (?) "Hptr". wp_pures. wp_load.
  iApply wp_fupd. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl". iApply "HΦ".
  iDestruct (own_slice_to_small with "Hsl") as "Hsl".
  iMod (readonly_alloc_1 with "Hsl") as "$". done.
Qed.

Lemma wp_mk_lconfig_hosts :
  {{{ True }}}
    mk_lconfig_hosts #()
  {{{ sl, RET (slice_val sl); readonly (own_slice_small sl uint64T 1 [ lconfigHost ]) }}}
.
  iIntros (?) "_ HΦ".
  wp_lam. wp_apply (wp_NewSlice).
  iIntros (?) "Hsl". wp_apply wp_ref_to; first by val_ty.
  iIntros (?) "Hptr". wp_pures. wp_load.
  iApply wp_fupd. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl". iApply "HΦ".
  iDestruct (own_slice_to_small with "Hsl") as "Hsl".
  iMod (readonly_alloc_1 with "Hsl") as "$". done.
Qed.

Lemma wp_mk_dconfig_paxosHosts :
  {{{ True }}}
    mk_dconfig_paxosHosts #()
  {{{ sl, RET (slice_val sl); own_slice_small sl uint64T 1 [ dconfigHostPaxos ] }}}
.
  iIntros (?) "_ HΦ".
  wp_lam. wp_apply (wp_NewSlice).
  iIntros (?) "Hsl". wp_apply wp_ref_to; first by val_ty.
  iIntros (?) "Hptr". wp_pures. wp_load.
  iApply wp_fupd. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl". iApply "HΦ".
  iDestruct (own_slice_to_small with "Hsl") as "Hsl". done.
Qed.

Lemma wp_mk_lconfig_paxosHosts :
  {{{ True }}}
    mk_lconfig_paxosHosts #()
  {{{ sl, RET (slice_val sl); own_slice_small sl uint64T 1 [ lconfigHostPaxos ] }}}
.
  iIntros (?) "_ HΦ".
  wp_lam. wp_apply (wp_NewSlice).
  iIntros (?) "Hsl". wp_apply wp_ref_to; first by val_ty.
  iIntros (?) "Hptr". wp_pures. wp_load.
  iApply wp_fupd. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl". iApply "HΦ".
  iDestruct (own_slice_to_small with "Hsl") as "Hsl". done.
Qed.

Lemma wpc_dconfig_main (params:configParams.t Σ) γ γsrv Φc fname data :
  params.(configParams.initconfig) = [dr1Host ; dr2Host] →
  ((∃ data' : list u8, config_crash_resources γ γsrv data' ∗ fname f↦data') -∗
    Φc) -∗
  ("#Hhost" ∷ is_config_server_host dconfigHost dconfigHostPaxos γ γsrv ∗
   "#Hpeers" ∷ is_config_peers [dconfigHostPaxos] γ ∗
   "#Hinvs" ∷ is_config_invs γ ∗
   "#Hwf" ∷ □ configParams.Pwf configParams.initconfig ∗

   "Hfile" ∷ fname f↦ data ∗
   "Hcrash" ∷ config_crash_resources γ γsrv data
  ) -∗
  WPC dconfig_main #(LitString fname) @ ⊤
  {{ _, True }}
  {{ Φc }}
.
Proof.
  intros Hinit.
  iIntros "HΦc H". iNamed "H".

  wpc_call.
  { iApply "HΦc". iExists _. iFrame. }

  iCache with "HΦc Hfile Hcrash".
  { iApply "HΦc". iExists _. iFrame. }
  wpc_bind (NewSlice _ _).
  wpc_frame.
  iApply wp_crash_borrow_generate_pre.
  { done. }
  wp_apply wp_NewSlice.
  iIntros (?) "Hsl".
  iIntros "Hpreborrow".
  iNamed 1.
  wpc_pures.

  iApply wpc_cfupd.
  wpc_apply (wpc_crash_borrow_inits with "Hpreborrow [Hcrash Hfile] []").
  { iAccu. }
  {
    iModIntro.
    instantiate (1:=(∃ data', config_crash_resources γ γsrv data' ∗ fname f↦ data')%I).
    iIntros "[H1 H2]".
    iExists _.
    iFrame.
  }
  iIntros "Hfile_ctx".
  wpc_apply (wpc_crash_mono _ _ _ _ _ (True%I) with "[HΦc]").
  { iIntros "_".
    iIntros "H".
    iModIntro.
    iApply "HΦc".
    done. }
  iApply wp_wpc.
  wp_pures.
  wp_apply (wp_ref_to); first by val_ty.
  iIntros (?) "Hservers".
  wp_pures.
  wp_load. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl".
  wp_store. wp_load.
  wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl".
  wp_store. wp_load.
  iDestruct (own_slice_to_small with "Hsl") as "Hsl".
  rewrite replicate_0 /=.
  iMod (readonly_alloc_1 with "Hsl") as "#Hsl".
  wp_apply wp_mk_dconfig_paxosHosts.
  iIntros (?) "HconfSl".
  wp_apply (wp_StartServer with "[$Hfile_ctx $HconfSl]").
  {
    rewrite Hinit.
    iFrame "#".
  }
  iIntros (?) "_".
  wp_pures.
  done.
Qed.

Lemma wpc_lconfig_main (params:configParams.t Σ) γ γsrv Φc fname data :
  params.(configParams.initconfig) = [lr1Host ; lr2Host] →
  ((∃ data' : list u8, config_crash_resources γ γsrv data' ∗ fname f↦data') -∗
    Φc) -∗
  ("#Hhost" ∷ is_config_server_host lconfigHost lconfigHostPaxos γ γsrv ∗
   "#Hpeers" ∷ is_config_peers [lconfigHostPaxos] γ ∗
   "#Hinvs" ∷ is_config_invs γ ∗
   "#Hwf" ∷ □ configParams.Pwf configParams.initconfig ∗

   "Hfile" ∷ fname f↦ data ∗
   "Hcrash" ∷ config_crash_resources γ γsrv data
  ) -∗
  WPC lconfig_main #(LitString fname) @ ⊤
  {{ _, True }}
  {{ Φc }}
.
Proof.
  intros Hinit.
  iIntros "HΦc H". iNamed "H".

  wpc_call.
  { iApply "HΦc". iExists _. iFrame. }

  iCache with "HΦc Hfile Hcrash".
  { iApply "HΦc". iExists _. iFrame. }
  wpc_bind (NewSlice _ _).
  wpc_frame.
  iApply wp_crash_borrow_generate_pre.
  { done. }
  wp_apply wp_NewSlice.
  iIntros (?) "Hsl".
  iIntros "Hpreborrow".
  iNamed 1.
  wpc_pures.

  iApply wpc_cfupd.
  wpc_apply (wpc_crash_borrow_inits with "Hpreborrow [Hcrash Hfile] []").
  { iAccu. }
  {
    iModIntro.
    instantiate (1:=(∃ data', config_crash_resources γ γsrv data' ∗ fname f↦ data')%I).
    iIntros "[H1 H2]".
    iExists _.
    iFrame.
  }
  iIntros "Hfile_ctx".
  wpc_apply (wpc_crash_mono _ _ _ _ _ (True%I) with "[HΦc]").
  { iIntros "_".
    iIntros "H".
    iModIntro.
    iApply "HΦc".
    done. }
  iApply wp_wpc.
  wp_pures.
  wp_apply (wp_ref_to); first by val_ty.
  iIntros (?) "Hservers".
  wp_pures.
  wp_load. wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl".
  wp_store. wp_load.
  wp_apply (wp_SliceAppend with "[$]").
  iIntros (?) "Hsl".
  wp_store. wp_load.
  iDestruct (own_slice_to_small with "Hsl") as "Hsl".
  rewrite replicate_0 /=.
  iMod (readonly_alloc_1 with "Hsl") as "#Hsl".
  wp_apply wp_mk_lconfig_paxosHosts.
  iIntros (?) "HconfSl".
  wp_apply (wp_StartServer with "[$Hfile_ctx $HconfSl]").
  {
    rewrite Hinit.
    iFrame "#".
  }
  iIntros (?) "_".
  wp_pures.
  done.
Qed.

Context `{!bankG Σ}.
Lemma wp_makeBankClerk γlk γkv :
  {{{
        "#Hhost1" ∷ is_kv_config_hosts [dconfigHost] γkv ∗
        "#Hhost2" ∷ is_kv_config_hosts [lconfigHost] γlk ∗
        "#Hbank" ∷ is_bank "init" (Build_lock_names (kv_ptsto γlk)) (kv_ptsto γkv) {[ "a1"; "a2" ]}
  }}}
    makeBankClerk #()
  {{{
        (b:loc), RET #b; own_bank_clerk b {[ "a1" ; "a2" ]}
  }}}
.
Proof.
  iIntros (?) "Hpre HΦ".
  iNamed "Hpre".
  wp_lam.
  wp_apply wp_mk_dconfig_hosts.
  iIntros (?) "#Hdsl".

  wp_apply (wp_MakeKv with "[$Hhost1]").
  { iFrame "#". }
  iIntros (?) "#Hkv".
  wp_pures.

  wp_apply wp_mk_lconfig_hosts.
  iIntros (?) "#Hlsl".
  wp_apply (wp_MakeKv with "[$Hhost2]").
  { iFrame "#". }
  iIntros (?) "Hlock_kv".
  wp_apply (wp_MakeLockClerk lockN with "[Hlock_kv]").
  {
    instantiate (3:=(Build_lock_names (kv_ptsto γlk))).
    iFrame. iPureIntro. solve_ndisj.
  }
  iIntros (?) "#Hlck".
  wp_pures.
  wp_apply (wp_MakeBankClerk with "[]").
  { iFrame "#". done. }
  iIntros (?) "Hb".
  iApply "HΦ".
  iFrame.
Qed.

Definition bank_pre : iProp Σ :=
  ∃ γkv γlk,
  "#Hhost1" ∷ is_kv_config_hosts [dconfigHost] γkv ∗
  "#Hhost2" ∷ is_kv_config_hosts [lconfigHost] γlk ∗
  "#Hbank" ∷ is_bank "init" (Build_lock_names (kv_ptsto γlk)) (kv_ptsto γkv) {[ "a1"; "a2" ]}
.

Lemma wp_bank_transferer_main :
  {{{
        bank_pre
  }}}
    bank_transferer_main #()
  {{{
        RET #(); True
  }}}
.
Proof.
  iIntros (?) "Hpre HΦ".
  iNamed "Hpre".
  wp_lam.
  wp_apply (wp_makeBankClerk with "[$]").
  iIntros (?) "Hck".
  wp_pures.
  wp_forBreak.
  wp_pures.
  wp_apply (Bank__SimpleTransfer_spec with "[$]").
  iIntros "Hck".
  wp_pures.
  iModIntro. iLeft. iFrame. done.
Qed.

Lemma wp_bank_auditor_main :
  {{{
        bank_pre
  }}}
    bank_auditor_main #()
  {{{
        RET #(); True
  }}}
.
Proof.
  iIntros (?) "Hpre HΦ".
  iNamed "Hpre".
  wp_lam.
  wp_apply (wp_makeBankClerk with "[$]").
  iIntros (?) "Hck".
  wp_pures.
  wp_forBreak.
  wp_pures.
  wp_apply (Bank__SimpleAudit_spec with "[$]").
  iIntros "Hck".
  wp_pures.
  iModIntro. iLeft. iFrame. done.
Qed.

End closed_wpcs.

Section closed_wprs.

#[global]
Instance is_kv_config_into_crash `{hG0: !heapGS Σ} `{!ekvG Σ} u γ:
  IntoCrash (is_kv_config_hosts u γ)
    (λ hG, ⌜ hG0.(goose_globalGS) = hG.(goose_globalGS) ⌝ ∗ is_kv_config_hosts u γ)%I
.
Proof.
  rewrite /IntoCrash /is_kv_config_hosts.
  iIntros "$". iIntros; eauto.
Qed.

#[global]
Instance is_kv_replica_host_into_crash `{hG0: !heapGS Σ} `{!ekvG Σ} u γ γsrv:
  IntoCrash (is_kv_replica_host u γ γsrv)
    (λ hG, ⌜ hG0.(goose_globalGS) = hG.(goose_globalGS) ⌝ ∗ is_kv_replica_host u γ γsrv)%I
.
Proof.
  rewrite /IntoCrash /is_kv_config_hosts.
  iIntros "$". iIntros; eauto.
Qed.

#[global]
Instance kv_crash_into_crash `{hG0: !heapGS Σ} `{!ekvG Σ} a b c:
  IntoCrash (kv_crash_resources a b c)
    (λ hG, (kv_crash_resources a b c))%I.
Proof.
  rewrite /IntoCrash /file_crash.
  iIntros "$". iIntros; eauto.
Qed.

Local Definition crash_cond {Σ} `{ekvG Σ} {fname γ γsrv} :=
  (λ hG : heapGS Σ, ∃ data, fname f↦ data ∗ ▷ kv_crash_resources γ γsrv data)%I.

Lemma wpr_kv_replica_main fname me configHost γ γsrv {Σ} {HKV: ekvG Σ}
                               {HG} {HL}:
  let hG := {| goose_globalGS := HG; goose_localGS := HL |} in
  ("#Hconf" ∷ is_kv_config_hosts [configHost] γ ∗
   "#Hhost" ∷ is_kv_replica_host me γ γsrv ∗
   "Hcrash" ∷ kv_crash_resources γ γsrv [] ∗
   "Hfile" ∷ fname f↦ []
  ) -∗
  wpr NotStuck ⊤ (kv_replica_main #(LitString fname) #me #configHost) (kv_replica_main #(LitString fname) #me #configHost) (λ _ : goose_lang.val, True)
    (λ _ , True) (λ _ _, True).
Proof.
  intros.
  iNamed 1.
  iApply (idempotence_wpr with "[Hfile Hcrash] []").
  {
    instantiate (1:=crash_cond).
    simpl.
    wpc_apply (wpc_kv_replica_main with "[]").
    { iIntros "$". }
    iFrame "∗#".
  }
  { (* recovery *)
    rewrite /hG.
    clear hG.
    iModIntro.
    iIntros (????) "Hcrash".
    iNext.
    iDestruct "Hcrash" as (?) "[Hfile Hcrash]".
    simpl.
    set (hG' := HeapGS _ _ hL').
    iDestruct "Hconf" as "-#Hconf".
    iDestruct "Hhost" as "-#Hhost".
    iCrash.
    iIntros "_".
    destruct hL as [HG'' ?].
    iSplit; first done.
    iDestruct "Hconf" as "(%&Hconf)".
    iDestruct "Hhost" as "(%&Hhost)".
    subst.
    simpl in *.
    clear hG'.
    clear hL'.
    (* overcome impedence mismatch between heapGS (bundled) and gooseGLobalGS+gooseLocalGS (split) proofs *)
    set (hG2' := HeapGS _ _ goose_localGS).
    simpl.
    wpc_apply (wpc_kv_replica_main (heapGS0:=hG2') with "[]").
    { iIntros "H".
      iDestruct "H" as (?) "[Hfile Hcrash]".
      iExists _.
      iFrame.
    }
    iFrame "∗#".
  }
Qed.

Local Definition config_crash_cond {Σ} `{configG Σ} {fname γ γsrv} {params:configParams.t Σ} :=
  (λ hG : heapGS Σ, ∃ data, config_crash_resources γ γsrv data ∗ fname f↦ data)%I.

Lemma wpr_dconfig_main {Σ} {HKV: ekvG Σ} (params:configParams.t Σ) fname γ γsrv
                               {HG} {HL}:
  let hG := {| goose_globalGS := HG; goose_localGS := HL |} in
  params.(configParams.initconfig) = [dr1Host ; dr2Host] →
  ("#Hhost" ∷ is_config_server_host dconfigHost dconfigHostPaxos γ γsrv ∗
   "#Hpeers" ∷ is_config_peers [dconfigHostPaxos] γ ∗
   "#Hinvs" ∷ is_config_invs γ ∗
   "#Hwf" ∷ □ configParams.Pwf configParams.initconfig ∗

   "Hfile" ∷ fname f↦ [] ∗
   "Hcrash" ∷ config_crash_resources γ γsrv []
  ) -∗
  wpr NotStuck ⊤ (dconfig_main #(LitString fname)) (dconfig_main #(LitString fname)) (λ _ : goose_lang.val, True)
    (λ _ , True) (λ _ _, True).
Proof.
  intros.
  iNamed 1.
  iApply (idempotence_wpr with "[Hfile Hcrash] []").
  {
    instantiate (1:=config_crash_cond).
    simpl.
    wpc_apply (wpc_dconfig_main with "[]").
    { done. }
    { iIntros "$". }
    iFrame "∗#".
  }
  { (* recovery *)
    rewrite /hG.
    clear hG.
    iModIntro.
    iIntros (????) "Hcrash".
    iNext.
    iDestruct "Hcrash" as (?) "[Hfile Hcrash]".
    simpl.
    set (hG' := HeapGS _ _ hL').
    iDestruct "Hhost" as "-#Hhost".
    (* FIXME: bundle invariants together. *)
    (*
    iDestruct "Hhost" as "-#Hhost".
    iCrash.
    iIntros "_".
    destruct hL as [HG'' ?].
    iSplit; first done.
    iDestruct "Hconf" as "(%&Hconf)".
    iDestruct "Hhost" as "(%&Hhost)".
    subst.
    simpl in *.
    clear hG'.
    clear hL'.
    (* overcome impedence mismatch between heapGS (bundled) and gooseGLobalGS+gooseLocalGS (split) proofs *)
    set (hG2' := HeapGS _ _ goose_localGS).
    simpl.
    wpc_apply (wpc_kv_replica_main (heapGS0:=hG2') with "[]").
    { iIntros "H".
      iDestruct "H" as (?) "[Hfile Hcrash]".
      iExists _.
      iFrame.
    }
    iFrame "∗#".
  } *)
Admitted.

Lemma wpr_lconfig_main {Σ} {HKV: ekvG Σ} (params:configParams.t Σ) fname γ γsrv
                               {HG} {HL}:
  let hG := {| goose_globalGS := HG; goose_localGS := HL |} in
  params.(configParams.initconfig) = [lr1Host ; lr2Host] →
  ("#Hhost" ∷ is_config_server_host lconfigHost lconfigHostPaxos γ γsrv ∗
   "#Hpeers" ∷ is_config_peers [lconfigHostPaxos] γ ∗
   "#Hinvs" ∷ is_config_invs γ ∗
   "#Hwf" ∷ □ configParams.Pwf configParams.initconfig ∗

   "Hfile" ∷ fname f↦ [] ∗
   "Hcrash" ∷ config_crash_resources γ γsrv []
  ) -∗
  wpr NotStuck ⊤ (lconfig_main #(LitString fname)) (lconfig_main #(LitString fname)) (λ _ : goose_lang.val, True)
    (λ _ , True) (λ _ _, True).
Proof.
  intros.
  iNamed 1.
  iApply (idempotence_wpr with "[Hfile Hcrash] []").
  {
    instantiate (1:=config_crash_cond).
    simpl.
    wpc_apply (wpc_lconfig_main with "[]").
    { done. }
    { iIntros "$". }
    iFrame "∗#".
  }
  { (* recovery *)
    rewrite /hG.
    clear hG.
    iModIntro.
    iIntros (????) "Hcrash".
    iNext.
    iDestruct "Hcrash" as (?) "[Hfile Hcrash]".
    simpl.
    set (hG' := HeapGS _ _ hL').
    iDestruct "Hhost" as "-#Hhost".
    (* FIXME: bundle invariants together. *)
    (*
    iDestruct "Hhost" as "-#Hhost".
    iCrash.
    iIntros "_".
    destruct hL as [HG'' ?].
    iSplit; first done.
    iDestruct "Hconf" as "(%&Hconf)".
    iDestruct "Hhost" as "(%&Hhost)".
    subst.
    simpl in *.
    clear hG'.
    clear hL'.
    (* overcome impedence mismatch between heapGS (bundled) and gooseGLobalGS+gooseLocalGS (split) proofs *)
    set (hG2' := HeapGS _ _ goose_localGS).
    simpl.
    wpc_apply (wpc_kv_replica_main (heapGS0:=hG2') with "[]").
    { iIntros "H".
      iDestruct "H" as (?) "[Hfile Hcrash]".
      iExists _.
      iFrame.
    }
    iFrame "∗#".
  } *)
Admitted.

End closed_wprs.

Section closed_init.

Context `{!gooseGlobalGS Σ}.
Context `{!ekvG Σ}.

Lemma alloc_vkv (replicaHosts:list u64) configHostPairs allocated :
  ([∗ list] h ∈ configHostPairs, h.1 c↦ ∅ ∗ h.2 c↦ ∅) ∗
  ([∗ list] h ∈ replicaHosts, h c↦ ∅)
  ={⊤}=∗ (∃ γ γsrvs,

  (* system-wide: allows clients to connect to the system, and gives them ownership of keys *)
  ([∗ set] k ∈ allocated, kv_ptsto γ k "") ∗
  is_kv_config_hosts (configHostPairs.*1) γ ∗

  (* for each kv replica server:  *)
  ([∗ list] host; γsrv ∈ replicaHosts ; γsrvs,
     is_kv_replica_host host γ γsrv ∗
     kv_crash_resources γ γsrv []
  )) ∗

  (* for each config paxos server:  *)
  ([∗ list] configHostPair ∈ configHostPairs,
    ∃ γconf γconfsrv params,
    ⌜ params.(configParams.initconfig) = replicaHosts ⌝ ∗
    is_config_server_host configHostPair.1 configHostPair.2 γconf γconfsrv ∗
    is_config_peers (configHostPairs.*2) γconf ∗
    is_config_invs γconf ∗
    (□ configParams.Pwf configParams.initconfig) ∗
    config_crash_resources γconf γconfsrv []
  )
.
Proof.
Admitted.

End closed_init.
