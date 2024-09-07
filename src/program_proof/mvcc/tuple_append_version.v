From Perennial.program_proof.mvcc Require Import tuple_prelude tuple_repr.

Section proof.
Context `{!heapGS Σ, !mvcc_ghostG Σ}.

(*****************************************************************)
(* func (tuple *Tuple) appendVersion(tid uint64, val string)     *)
(*****************************************************************)
Theorem wp_tuple__appendVersion tuple (tid : u64) (val : string) owned tidlast vers :
  {{{ own_tuple_phys tuple owned tidlast vers }}}
    Tuple__appendVersion #tuple #tid #(LitString val)
  {{{ RET #(); own_tuple_phys tuple false (W64 (uint.Z tid + 1)) (vers ++ [(tid, false, val)]) }}}.
Proof.
  iIntros (Φ) "Hphys HΦ".
  iNamed "Hphys".
  wp_rec. wp_pures.
  
  (***********************************************************)
  (* verNew := Version{                                      *)
  (*     begin   : tid,                                      *)
  (*     val     : val,                                      *)
  (*     deleted : false,                                    *)
  (* }                                                       *)
  (* tuple.vers = append(tuple.vers, verNew)                 *)
  (***********************************************************)
  wp_loadField.
  wp_apply (wp_SliceAppend with "[HversS]"); [done | auto 10 with iFrame |].
  iIntros (vers') "HversS". 
  wp_storeField.

  (***********************************************************)
  (* tuple.owned = false                                     *)
  (* tuple.tidlast = tid + 1                                 *)
  (***********************************************************)
  do 2 wp_storeField.

  iModIntro.
  iApply "HΦ".
  unfold own_tuple_phys.
  iExists _.
  iFrame.
  iExactEq "HversS".
  unfold named.
  f_equal.
  by rewrite fmap_app.
Qed.

(*****************************************************************)
(* func (tuple *Tuple) AppendVersion(tid uint64, val string)     *)
(*****************************************************************)
Theorem wp_tuple__AppendVersion
        tuple (tid : u64) (val : string) (key : u64) (sid : u64)
        (phys : list dbval) γ :
  {{{ active_tid γ tid sid ∗
      own_tuple_locked tuple key (uint.nat tid) phys (extend (S (uint.nat tid)) phys ++ [Value val]) γ
  }}}
    Tuple__AppendVersion #tuple #tid #(LitString val)
  {{{ RET #(); active_tid γ tid sid }}}.
Proof.
  iIntros (Φ) "[Hactive H] HΦ".
  wp_rec. wp_pures.

  (***********************************************************)
  (* tuple.appendVersion(tid, val)                           *)
  (***********************************************************)
  iNamed "H".
  wp_apply (wp_tuple__appendVersion with "Hphys").
  iIntros "Hphys".
  wp_pures.
  
  (***********************************************************)
  (* tuple.rcond.Broadcast()                                 *)
  (***********************************************************)
  iNamed "Hlock".
  wp_loadField.
  wp_apply (wp_Cond__Broadcast with "[$HrcondC]").

  (***********************************************************)
  (* tuple.latch.Unlock()                                    *)
  (***********************************************************)
  iNamed "Hrepr".
  iApply fupd_wp.
  iInv "Hinvgc" as ">HinvgcO" "HinvgcC".
  iDestruct (active_ge_min with "HinvgcO Hactive Hgclb") as "%HtidGe".
  iMod ("HinvgcC" with "HinvgcO") as "_".
  iModIntro.
  wp_loadField.
  assert (HlenN : length phys = S (uint.nat tidlast)) by word.
  iAssert (⌜uint.Z tid < 2 ^ 64 - 1⌝)%I with "[Hactive]" as "%Htidmax".
  { iDestruct "Hactive" as "[_ %H]". iPureIntro. word. }
  wp_apply (wp_Mutex__Unlock with "[-HΦ Hactive]").
  { iFrame "Hlock Hlocked".
    iNext.
    erewrite extend_last_Some; last apply Hlast.
    rewrite -app_assoc.
    set phys' := phys ++ _ ++ _.
    iExists false, (W64 (uint.Z tid + 1)), tidgc, _, phys'.
    iFrame "Hphys Hptuple".
    iNamed "Hwellformed".
    iSplit.
    { (* Prove [HtupleAbs]. *)
      iPureIntro.
      simpl.
      intros tidx Htidx.
      destruct (decide (uint.Z tidx ≤ uint.Z tidlast)); subst phys'.
      - (* Reading the non-extension part. *)
        rewrite lookup_app_l; last word.
        rewrite HtupleAbs; last word.
        symmetry.
        f_equal.
        apply spec_lookup_snoc_l with tid; [done | word].
      - (* Reading the extension part. *)
        rewrite lookup_app_r; last word.
        apply Znot_le_gt in n.
        destruct (decide (uint.Z tidx ≤ uint.Z tid)).
        + (* Reading the old value. *)
          rewrite lookup_app_l; last first.
          { rewrite HlenN length_replicate. word. }
          rewrite lookup_replicate_2; last word.
          f_equal.
          rewrite (spec_lookup_snoc_l _ _ _ tid); [| auto | word].
          apply spec_lookup_extensible with tidlast; [word | word | auto].
        + (* Reading the new value. *)
          apply Znot_le_gt in n0.
          rewrite lookup_app_r; last first.
          { rewrite HlenN length_replicate. word. }
          replace (uint.Z (W64 _)) with (uint.Z tid + 1) in Htidx by word.
          assert (Etidx : uint.Z tidx = uint.Z tid + 1) by word.
          replace (uint.nat tidx - _ - _)%nat with 0%nat; last first.
          { rewrite length_replicate. word. }
          simpl. f_equal.
          rewrite (spec_lookup_snoc_r _ _ _ tid); [done | auto | word].
    }
    iSplit.
    { (* Prove [Hlast]. *)
      iPureIntro.
      subst phys'.
      rewrite app_assoc.
      rewrite last_snoc.
      f_equal.
      rewrite (spec_lookup_snoc_r _ _ _ tid); [done | by simpl | word].
    }
    iSplit.
    { (* Prove [HvchainLen]. *)
      iPureIntro.
      subst phys'.
      do 2 rewrite length_app.
      rewrite HlenN length_replicate singleton_length. word.
    }
    iSplit; first done.
    { (* Prove [Hwellformed]. *)
      iPureIntro.
      split.
      { (* Prove [HtidlastGe]. *)
        apply Forall_app_2.
        - apply (Forall_impl _ _ _ HtidlastGt).
          intros verx Hverx.
          trans (uint.Z tid); word.
        - rewrite Forall_singleton. simpl. word.
      }
      split.
      { (* Prove [HexistsLt]. *)
        intros tidx HtidxGZ Htidx.
        apply Exists_app.
        left.
        apply HexistsLt; done.
      }
      split.
      { (* Prove [HtidgcLe]. *)
        destruct vers eqn:Evers; first contradiction.
        simpl.
        apply Forall_app_2; first done.
        rewrite Forall_singleton. simpl.
        word.
      }
      { (* Prove [Hnotnil]. *)
        apply not_eq_sym.
        apply app_cons_not_nil.
      }
    }
  }

  (* Return. *)
  wp_pures.
  by iApply "HΦ".
Qed.

End proof.
