From iris.proofmode Require Import coq_tactics reduction.
From iris.proofmode Require Import tactics.
From iris.proofmode Require Import environments.
From iris.bi.lib Require Import fractional.
From Perennial.program_logic Require Import weakestpre.
From New.golang.defn Require Export mem.
From New.golang.theory Require Import proofmode typing.
Require Import Coq.Program.Equality.
From Ltac2 Require Import Ltac2.
Set Default Proof Mode "Classic".

Set Default Proof Using "Type".

Section goose_lang.
  Context `{ffi_sem: ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ}.

  Context `{!IntoVal V}.
  Context `{!IntoValTyped V t}.
  Implicit Type v : V.
  Program Definition typed_pointsto_def l (dq : dfrac) (v : V) : iProp Σ :=
    (([∗ list] j↦vj ∈ flatten_struct (to_val v), heap_pointsto (l +ₗ j) dq vj))%I.
  Definition typed_pointsto_aux : seal (@typed_pointsto_def). Proof. by eexists. Qed.
  Definition typed_pointsto := typed_pointsto_aux.(unseal).
  Definition typed_pointsto_unseal : @typed_pointsto = @typed_pointsto_def := typed_pointsto_aux.(seal_eq).

  Notation "l ↦ dq v" := (typed_pointsto l dq v%V)
                                   (at level 20, dq custom dfrac at level 1,
                                    format "l  ↦ dq  v") : bi_scope.

  Ltac unseal := rewrite ?typed_pointsto_unseal /typed_pointsto_def.

  Global Instance typed_pointsto_timeless l q v : Timeless (l ↦{q} v).
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_persistent l v : Persistent (l ↦□ v).
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_fractional l v : Fractional (λ q, l ↦{#q} v)%I.
  Proof. unseal. apply _. Qed.

  Global Instance typed_pointsto_as_fractional l v q : AsFractional
                                                     (l ↦{#q} v)
                                                     (λ q, l ↦{#q} v)%I q.
  Proof. constructor; auto. apply _. Qed.

  Global Instance struct_fields_val_inj :
    Inj (=) (=) struct.fields_val.
  Proof.
    rewrite struct.fields_val_unseal /struct.fields_val_def.
    intros ?? Heq.
    dependent induction y generalizing x;
    destruct x as [|[]]; try done.
    { destruct a; done. }
    destruct a.
    injection Heq as Heq.
    subst.
    eapply inj in Heq; last apply _.
    subst.
    f_equal.
    by apply IHy.
  Qed.

  Local Lemma flatten_struct_inj (v1 v2 : val) :
    has_go_type v1 t → has_go_type v2 t →
    flatten_struct v1 = flatten_struct v2 → v1 = v2.
  Proof.
    intros Hty1 Hty2 Heq.
    clear dependent V.
    dependent induction Hty1 generalizing v2.
    Ltac2 step () :=
      match! goal with
      | [ v : slice.t |- _ ] => let v := Control.hyp v in destruct $v
      | [ v : interface.t |- _ ] => let v := Control.hyp v in destruct $v
      | [ v : func.t |- _ ] => let v := Control.hyp v in destruct $v
      | [ h : has_go_type _ _ |- _ ] => let h := Control.hyp h in (inversion_clear $h in Heq)
      | [ h : struct.fields_val _ = struct.fields_val _ |- _ ] => apply struct_fields_val_inj in $h; subst

      (* unseal whatever's relevant *)
      | [ h : context [struct.val_aux]  |- _ ] => rewrite !struct.val_aux_unseal in $h
      | [ |- context [struct.val_aux] ] => rewrite !struct.val_aux_unseal
      | [ h : context [to_val]  |- _ ] => rewrite !to_val_unseal in $h
      | [ |- context [to_val] ] => rewrite !to_val_unseal

      | [ h : (flatten_struct _ = flatten_struct _) |- _ ] => progress (simpl in $h)
      | [ h : cons _ _ = cons _ _  |- _ ] =>
          Std.inversion Std.FullInversion (Std.ElimOnIdent h) None None;
          clear $h; subst
      | [ h : context [length (cons _ _)] |- _ ] => progress (simpl in $h)
      | [ h : context [length []] |- _ ] => progress (simpl in $h)
      | [ |- _ ] => reflexivity
      | [ |- _ ] => discriminate
      end
    .
    all: repeat ltac2:(step ()).
    {
      (* XXX: need to reorder hyps to avoid an error in [dependent induction].... *)
      move a after a0.
      dependent induction a generalizing a0.
      { dependent destruction a0. done. }
      dependent destruction a0.
      simpl in Heq.
      apply app_inj_1 in Heq as [? ?].
      2:{ by do 2 erewrite has_go_type_len by naive_solver. }
      simpl. f_equal.
      + apply H; naive_solver.
      + apply IHa; naive_solver.
    }
    {
      induction d as [|[]d]; repeat ltac2:(step ()).
      simpl in *.
      apply app_inj_1 in Heq as [? ?].
      2:{ by do 2 erewrite has_go_type_len by naive_solver. }
      f_equal.
      + apply H; naive_solver.
      + apply IHd; naive_solver.
    }
  Qed.

  Global Instance typed_pointsto_combine_sep_gives l dq1 dq2 v1 v2 :
    CombineSepGives (l ↦{dq1} v1)%I (l ↦{dq2} v2)%I
                    ⌜ (go_type_size t > O → ✓(dq1 ⋅ dq2)) ∧ v1 = v2 ⌝%I.
  Proof using IntoValTyped0.
    unfold CombineSepGives.
    unseal.
    iIntros "[H1 H2]".
    rename l into l'.
    pose proof (to_val_has_go_type v1) as H1.
    pose proof (to_val_has_go_type v2) as H2.
    pose proof (flatten_struct_inj _ _ H1 H2).
    iDestruct (big_sepL2_sepL_2 with "H1 H2") as "H".
    { do 2 (erewrite has_go_type_len by done). done. }
    iDestruct (big_sepL2_impl with "H []") as "H".
    {
      iModIntro. iIntros "*%%[H1 H2]".
      iCombine "H1 H2" gives %Heq.
      instantiate(1:=(λ _ _ _, ⌜ _ ⌝%I )).
      simpl. iPureIntro. exact Heq.
    }
    iDestruct (big_sepL2_pure with "H") as %[Hlen Heq].
    iModIntro. iPureIntro.
    split.
    { intros. specialize (Heq 0%nat).
      destruct (flatten_struct (# v1)) eqn:Hbad.
      { exfalso. apply (f_equal length) in Hbad. rewrite (has_go_type_len (t:=t)) /= in Hbad; [lia|done]. }
      clear Hbad.
      destruct (flatten_struct (# v2)) eqn:Hbad.
      { exfalso. apply (f_equal length) in Hbad. rewrite (has_go_type_len (t:=t)) /= in Hbad; [lia|done]. }
      specialize (Heq v v0 ltac:(done) ltac:(done)) as [??]. assumption.
    }
    {
      apply to_val_inj, H.
      apply list_eq.
      intros.
      replace i with (i + 0)%nat by lia.
      rewrite <- !lookup_drop.
      destruct (drop i $ flatten_struct (# v1)) eqn:Hlen1, (drop i $ flatten_struct (# v2)) eqn:Hlen2.
      { done. }
      1-2: exfalso; apply (f_equal length) in Hlen1, Hlen2;
        rewrite !length_drop in Hlen1, Hlen2;
        simpl in *; lia.
      specialize (Heq i v v0).
      replace i with (i + 0)%nat in Heq by lia.
      rewrite <- !lookup_drop in Heq.
      rewrite Hlen1 Hlen2 in Heq.
      simpl in Heq.
      unshelve epose proof (Heq _ _); naive_solver.
    }
  Qed.

  Lemma typed_pointsto_persist l dq v :
    l ↦{dq} v ==∗ l ↦□ v.
  Proof.
    unseal. iIntros "?".
    iApply big_sepL_bupd.
    iApply (big_sepL_impl with "[$]").
    iModIntro. iIntros.
    iApply (heap_pointsto_persist with "[$]").
  Qed.

  Lemma typed_pointsto_not_null l dq v :
    go_type_size t > 0 →
    l ↦{dq} v -∗ ⌜ l ≠ null ⌝.
  Proof using IntoValTyped0.
    unseal. intros Hlen. iIntros "?".
    pose proof (to_val_has_go_type v) as Hty.
    generalize dependent (# v). clear dependent V. intros v Hty.
    iInduction Hty as [] "IH"; subst;
    simpl; rewrite ?to_val_unseal /= ?right_id ?loc_add_0;
      try (iApply heap_pointsto_non_null; by iFrame).
    - (* array *)
      rewrite go_type_size_unseal /= in Hlen.
      destruct a as [|].
      { exfalso. simpl in *. lia. }
      destruct (decide (go_type_size_def elem = O)).
      { exfalso. rewrite e in Hlen. simpl in *. lia. }
      iDestruct select ([∗ list] _ ↦ _ ∈ _, _)%I as "[? _]".
      iApply ("IH" $! h with "").
      + naive_solver.
      + iPureIntro. rewrite go_type_size_unseal. lia.
      + iFrame.
    - (* struct *)
      rewrite go_type_size_unseal /= in Hlen.
      iInduction d as [|[]] "IH2"; simpl in *.
      { exfalso. lia. }
      rewrite struct.val_aux_unseal /=.
      destruct (decide (go_type_size_def g = O)).
      {
        rewrite (nil_length_inv (flatten_struct (default _ _))).
        2:{
          erewrite has_go_type_len.
          { rewrite go_type_size_unseal. done. }
          apply Hfields. by left.
        }
        rewrite app_nil_l.
        iApply ("IH2" with "[] [] [] [$]").
        - iPureIntro. intros. apply Hfields. by right.
        - iPureIntro. lia.
        - iModIntro. iIntros. iApply ("IH" with "[] [] [$]").
          + iPureIntro. by right.
          + iPureIntro. lia.
      }
      {
        iDestruct select ([∗ list] _ ↦ _ ∈ _, _)%I as "[? _]".
        iApply ("IH" with "[] [] [$]").
        - iPureIntro. by left.
        - iPureIntro. rewrite go_type_size_unseal. lia.
      }
  Qed.

  Lemma wp_ref_ty stk E (v : V) :
    {{{ True }}}
      ref_ty t (# v) @ stk; E
    {{{ l, RET #l; l ↦ v }}}.
  Proof.
    iIntros (Φ) "_ HΦ".
    rewrite ref_ty_unseal.
    wp_call.
    iApply (wp_allocN_seq with "[//]"); first by word. iNext.
    change (uint.nat 1) with 1%nat; simpl.
    iIntros (l) "[Hl _]".
    rewrite to_val_unseal /= -to_val_unseal.
    iApply "HΦ".
    unseal.
    rewrite Z.mul_0_r loc_add_0.
    iFrame.
  Qed.

  Lemma wp_load_ty stk E q l v :
    {{{ ▷ l ↦{q} v }}}
      load_ty t #l @ stk; E
    {{{ RET #v; l ↦{q} v }}}.
  Proof using IntoValTyped0.
    iIntros (Φ) ">Hl HΦ".
    unseal.
    pose proof (to_val_has_go_type v) as Hty.
    generalize dependent (# v). clear dependent V.
    intros v Hty.
    iAssert (▷ (([∗ list] j↦vj ∈ flatten_struct v, heap_pointsto (l +ₗ j) q vj) -∗ Φ v))%I with "[HΦ]" as "HΦ".
    { iIntros "!> HPost".
      iApply "HΦ". iFrame. }
    rewrite load_ty_unseal.
    rename l into l'.
    iInduction Hty as [] "IH" forall (l' Φ) "HΦ".
    all: rewrite ?to_val_unseal /= /= ?loc_add_0 ?right_id; wp_pures.
    all: try (iApply (wp_load with "[$]"); done).
    - (* case arrayT *)
      subst.
      iInduction a as [|] "IH2" forall (l' Φ).
      { simpl. wp_pures. rewrite to_val_unseal. iApply "HΦ". by iFrame. }
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      simpl. wp_pures.
      simpl.
      wp_apply ("IH" with "[] Hf").
      { iPureIntro. by left. }
      iIntros "Hf".
      wp_pures.
      replace (LitV (LitLoc l')) with (# l').
      2:{ by rewrite to_val_unseal. }
      wp_pures.
      rewrite to_val_unseal /=.
      wp_apply ("IH2" with "[] [] [Hl]").
      { iPureIntro. intros. apply Helems. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [$] [$]").
        iPureIntro. by right. }
      {
        erewrite has_go_type_len.
        2:{ eapply Helems. by left. }
        rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
        iFrame.
      }
      iIntros "Hl".
      wp_pures.
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems. by left. }
      rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      by iFrame.
    - (* case structT *)
      rewrite struct.val_aux_unseal.
      iInduction d as [|] "IH2" forall (l' Φ).
      { wp_pures. iApply "HΦ". by iFrame. }
      destruct a.
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      wp_apply ("IH" with "[] Hf").
      { iPureIntro. by left. }
      iIntros "Hf".
      replace (LitV (LitLoc l')) with (# l').
      2:{ by rewrite to_val_unseal. }
      wp_pures.
      simpl.
      ltac2:(wp_bind_apply ()).
      rewrite [in (to_val (l' +ₗ _))]to_val_unseal.
      wp_apply ("IH2" with "[] [] [Hl]").
      { iPureIntro. intros. apply Hfields. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [$] [$]").
        iPureIntro. by right. }
      {
        erewrite has_go_type_len.
        2:{ eapply Hfields. by left. }
        rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
        iFrame.
      }
      iIntros "Hl".
      wp_pures.
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields. by left. }
      rewrite right_id. setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      by iFrame.
  Qed.

  Lemma wp_store stk E l (v v' : val) :
    {{{ ▷ heap_pointsto l (DfracOwn 1) v' }}} Store (Val $ LitV (LitLoc l)) (Val v) @ stk; E
    {{{ RET LitV LitUnit; heap_pointsto l (DfracOwn 1) v }}}.
  Proof.
    iIntros (Φ) "Hl HΦ". wp_call.
    wp_bind (PrepareWrite _).
    iApply (wp_prepare_write with "Hl"); iNext; iIntros "[Hl Hl']".
    wp_pures.
    by iApply (wp_finish_store with "[$Hl $Hl']").
  Qed.

  Lemma wp_store_ty stk E l v v' :
    {{{ ▷ l ↦ v }}}
      (#l <-[t] #v')%V @ stk; E
    {{{ RET #(); l ↦ v' }}}.
  Proof using IntoValTyped0.
    iIntros (Φ) ">Hl HΦ".
    unseal.
    pose proof (to_val_has_go_type v) as Hty_old.
    pose proof (to_val_has_go_type v') as Hty.
    generalize dependent #v. generalize dependent #v'.
    clear dependent V. intros v' Hty v Hty_old.
    iAssert (▷ (([∗ list] j↦vj ∈ flatten_struct v', heap_pointsto (l +ₗ j) (DfracOwn 1) vj) -∗ Φ #()))%I with "[HΦ]" as "HΦ".
    { iIntros "!> HPost".
      iApply "HΦ". iFrame. }
    rename l into l'.
    rewrite store_ty_unseal.
    iInduction Hty_old as [] "IH" forall (v' Hty l' Φ) "HΦ".
    all: inversion_clear Hty; subst; rewrite ?to_val_unseal /= ?loc_add_0 ?right_id;
      wp_pures.
    all: try (wp_apply (wp_store with "[$]"); iIntros "H"; iApply "HΦ"; iFrame).
    - (* array *)
      rename a0 into a'.
      iInduction a as [|] "IH2" forall (l' a' Helems0).
      { wp_pures. rewrite ?to_val_unseal. iApply "HΦ".
        dependent destruction a'. done. }
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      dependent destruction a'.
      simpl.
      wp_pures.
      wp_apply ("IH" with "[] [] [$Hf]").
      { iPureIntro. simpl. by left. }
      { iPureIntro. apply Helems0. by left. }
      iIntros "Hf".
      replace (LitV l') with (#l').
      2:{ rewrite to_val_unseal //. }
      wp_pures.
      rewrite [in (to_val (l' +ₗ _))]to_val_unseal.
      wp_apply ("IH2" with "[] [] [] [Hl]").
      { iPureIntro. intros. apply Helems. by right. }
      { iPureIntro. intros. apply Helems0. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { rewrite ?right_id. iFrame. }
      iIntros "Hl".
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Helems0. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      rewrite ?right_id. iFrame.
    - (* struct *)
      rewrite struct.val_aux_unseal.
      unfold struct.val_aux_def.
      iInduction d as [|] "IH2" forall (l').
      { wp_pures. rewrite to_val_unseal /=. iApply "HΦ". done. }
      destruct a.
      wp_pures.
      iDestruct "Hl" as "[Hf Hl]".
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      wp_apply ("IH" with "[] [] [$Hf]").
      { iPureIntro. simpl. by left. }
      { iPureIntro. apply Hfields0. by left. }
      iIntros "Hf".
      replace (LitV l') with (#l').
      2:{ rewrite to_val_unseal //. }
      wp_pures.
      rewrite [in (to_val (l' +ₗ _))]to_val_unseal.
      wp_apply ("IH2" with "[] [] [] [Hl]").
      { iPureIntro. intros. apply Hfields. by right. }
      { iPureIntro. intros. apply Hfields0. by right. }
      { iModIntro. iIntros. wp_apply ("IH" with "[] [//] [$] [$]"). iPureIntro. by right. }
      { rewrite ?right_id. iFrame. }
      iIntros "Hl".
      iApply "HΦ".
      iFrame.
      fold flatten_struct.
      erewrite has_go_type_len.
      2:{ eapply Hfields0. by left. }
      setoid_rewrite Nat2Z.inj_add. setoid_rewrite <- loc_add_assoc.
      rewrite ?right_id. iFrame.
  Qed.

  Definition is_primitive_type (t : go_type) : Prop :=
    match t with
    | structT d => False
    | arrayT n t => False
    | funcT => False
    | sliceT => False
    | interfaceT => False
    | _ => True
    end.

  Lemma wp_typed_cmpxchg_fail s E l dq v' v1 v2 :
    is_primitive_type t →
    #v' ≠ #v1 →
    {{{ ▷ l ↦{dq} v' }}} CmpXchg (Val # l) #v1 #v2 @ s; E
    {{{ RET (#v', #false); l ↦{dq} v' }}}.
  Proof using Type*.
    pose proof (to_val_has_go_type v') as Hty_old.
    pose proof (to_val_has_go_type v1) as Hty.
    unseal.
    generalize dependent (to_val v1). generalize dependent (to_val v'). generalize dependent (to_val v2).
    intros.
    clear dependent V.
    rewrite to_val_unseal.
    iIntros "Hl HΦ".
    destruct t; try by exfalso.
    all: inversion Hty_old; subst; inversion Hty; subst;
      simpl; rewrite to_val_unseal /= in H0 |- *;
      rewrite loc_add_0 right_id;
      iApply (wp_cmpxchg_fail with "[$]"); first done; first (by econstructor);
      iIntros; iApply "HΦ"; iFrame; done.
  Qed.

  Lemma wp_typed_cmpxchg_suc s E l v' v1 v2 :
    is_primitive_type t →
    #v' = #v1 →
    {{{ ▷ l ↦ v' }}} CmpXchg #l #v1 #v2 @ s; E
    {{{ RET (#v', #true); l ↦ v2 }}}.
  Proof using Type*.
    intros Hprim Heq.
    pose proof (to_val_has_go_type v') as Hty_old.
    pose proof (to_val_has_go_type v2) as Hty.
    unseal.
    generalize dependent (#v1). generalize dependent (#v'). generalize dependent (#v2).
    clear dependent V.
    intros.
    iIntros "Hl HΦ".
    destruct t; try by exfalso.
    all: inversion Hty_old; subst;
      inversion Hty; subst;
      simpl; rewrite to_val_unseal /= loc_add_0 !right_id;
      iApply (wp_cmpxchg_suc with "[$Hl]"); first done; first (by econstructor);
      iIntros; iApply "HΦ"; iFrame; done.
  Qed.

End goose_lang.

Notation "l ↦ dq v" := (typed_pointsto l dq v%V)
                              (at level 20, dq custom dfrac at level 50,
                               format "l  ↦ dq  v") : bi_scope.

Section tac_lemmas.
  Context `{ffi_sem: ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ}.

  Class PointsToAccess {V Vsmall}
    {t tsmall} `{!IntoVal V} `{!IntoVal Vsmall} `{!IntoValTyped V t} `{!IntoValTyped Vsmall tsmall}
    (l' l : loc) (v : V) (vsmall : Vsmall) (update : Vsmall → V → V) : Prop :=
    {
      points_to_acc : ∀ dq, l' ↦{dq} v -∗ l ↦{dq} vsmall ∗
                            (∀ vsmall', l ↦{dq} vsmall' -∗ l' ↦{dq} (update vsmall' v));
      points_to_update_eq : update vsmall v = v
    }.

  Lemma tac_wp_load_ty {V t Vsmall tsmall}
    `{!IntoVal V} `{!IntoValTyped V t} `{!IntoVal Vsmall} `{!IntoValTyped Vsmall tsmall}
    (l' l : loc) (v : V) (vsmall : Vsmall) update Δ s E i dq Φ is_pers
    `{!PointsToAccess l' l v vsmall update} :
    envs_lookup i Δ = Some (is_pers, l' ↦{dq} v)%I →
    envs_entails Δ (Φ #vsmall) →
    envs_entails Δ (WP (load_ty tsmall #l) @ s; E {{ Φ }}).
  Proof using Type*.
    rewrite envs_entails_unseal => ? HΦ.
    rewrite envs_lookup_split //.
    iIntros "[H Henv]".
    destruct is_pers; simpl.
    - iDestruct "H" as "#H".
      iDestruct (points_to_acc with "H") as "[H' _]".
      unshelve wp_apply (wp_load_ty with "[$]"); first apply _.
      iIntros "?".
      iApply HΦ. iApply "Henv". iFrame "#".
    - iDestruct (points_to_acc with "H") as "[H Hclose]".
      unshelve wp_apply (wp_load_ty with "[$]"); first apply _.
      iIntros "?".
      iApply HΦ. iApply "Henv".
      iSpecialize ("Hclose" with "[$]").
      rewrite points_to_update_eq. iFrame.
  Qed.

  Lemma tac_wp_store_ty {V t Vsmall tsmall}
    `{!IntoVal V} `{!IntoValTyped V t} `{!IntoVal Vsmall} `{!IntoValTyped Vsmall tsmall}
    (l' l : loc) (v : V) (vsmall vsmall' : Vsmall) update Δ Δ' s E i Φ
    `{!PointsToAccess l' l v vsmall update} :
    envs_lookup i Δ = Some (false, l' ↦ v)%I →
    envs_simple_replace i false (Esnoc Enil i (l' ↦ (update vsmall' v))) Δ = Some Δ' →
    envs_entails Δ' (Φ #()) →
    envs_entails Δ (WP (store_ty tsmall #l (Val #vsmall')) @ s; E {{ Φ }}).
  Proof.
    rewrite envs_entails_unseal => ?? HΦ.
    eapply bi.wand_apply; first by eapply bi.wand_entails, wp_store_ty.
    rewrite -bi.later_sep envs_simple_replace_sound // /= right_id -bi.later_intro.
    iIntros "[Hl Hw]".
    unshelve iDestruct (points_to_acc with "Hl") as "[$ Hl]".
    iIntros "?". iSpecialize ("Hl" with "[$]").
    iApply HΦ. by iApply "Hw".
  Qed.

  Lemma tac_wp_ref_ty
    `{!IntoVal V} `{!IntoValTyped V t}
    Δ stk E (v : V) Φ :
    (∀ l, envs_entails Δ (l ↦ v -∗ Φ #l)) →
    envs_entails Δ (WP (ref_ty t #v) @ stk; E {{ Φ }}).
  Proof.
    rewrite envs_entails_unseal => Hwp.
    eapply bi.wand_apply; first by eapply bi.wand_entails, wp_ref_ty.
    rewrite left_id -bi.later_intro.
    by apply bi.forall_intro.
  Qed.

  Global Instance points_to_access_trivial {V} l (v : V) {t} `{!IntoVal V} `{!IntoValTyped V t}
    : PointsToAccess l l v v (λ v' _, v').
  Proof. constructor; [eauto with iFrame|done]. Qed.

End tac_lemmas.

Ltac2 tc_solve_many () := solve [ltac1:(typeclasses eauto)].
Ltac2 wp_load () :=
  lazy_match! goal with
  | [ |- envs_entails _ (wp _ _ _ _) ] =>
      let _ := (orelse
                  (fun () =>
                     let e := wp_bind_filter (Std.unify '(load_ty _ (Val _))) in
                     match! e with (App (Val (load_ty _)) (Val #?l)) => l end
                  )
                  (fun _ => Control.backtrack_tactic_failure "wp_load: could not bind to load instruction")
               ) in

      (* The orelse avoids failures higher-level from backtracking down into the
         tc_solve_many here, but allows failed iAssumptionCore to backtrack. *)
      orelse (fun _ => eapply (tac_wp_load_ty) > [tc_solve_many ()| ltac1:(iAssumptionCore) |])
        (fun _ => Control.backtrack_tactic_failure "wp_load: could not find a points-to in context covering the address")
  end.

Ltac2 wp_store () :=
  lazy_match! goal with
  | [ |- envs_entails _ (wp _ _ _ _) ] =>
      orelse (fun () => let _ := wp_bind_filter (Std.unify '(store_ty _ _ (Val _))) in ())
        (fun _ => Control.backtrack_tactic_failure "wp_store: could not bind to store instruction");
      (* XXX: we want to backtrack to typeclass search if [iAssumptionCore] failed. *)

      (* The orelse avoids failures higher-level from backtracking down into the tc_solve_many here. *)
      orelse (fun _ => eapply (tac_wp_store_ty) > [tc_solve_many ()| ltac1:(iAssumptionCore)
                                               |ltac1:(pm_reflexivity) | ])
        (fun _ => Control.backtrack_tactic_failure "wp_store: could not find a points-to in context covering the address")
  end.

Tactic Notation "wp_alloc" ident(l) "as" constr(H) :=
  first [wp_bind (ref_ty _ _) | fail "cannot find ref_ty"];
  (eapply tac_wp_ref_ty || fail "cannot apply wp_ref_ty");
  iIntros (l) H.

Tactic Notation "wp_load" := ltac2:(Control.enter wp_load).
Tactic Notation "wp_store" := ltac2:(Control.enter wp_store).
