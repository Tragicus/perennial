From RecordUpdate Require Import RecordSet.
Import RecordSetNotations.

From Perennial.algebra Require Import deletable_heap liftable auth_map.
From Perennial.Helpers Require Import Transitions.
From Perennial.program_proof Require Import proof_prelude.

From Goose.github_com.mit_pdos.goose_nfsd Require Import simple.
From Perennial.program_proof Require Import txn.txn_proof marshal_proof addr_proof crash_lockmap_proof addr.addr_proof buf.buf_proof.
From Perennial.program_proof Require Import buftxn.sep_buftxn_proof.
From Perennial.program_proof Require Import proof_prelude.
From Perennial.program_proof Require Import disk_lib.
From Perennial.Helpers Require Import NamedProps Map List range_set.
From Perennial.algebra Require Import log_heap.
From Perennial.program_logic Require Import spec_assert.
From Perennial.goose_lang.lib Require Import slice.typed_slice into_val.
From Perennial.program_proof Require Import simple.spec.

Section heap.
Context `{!buftxnG Σ}.
Context `{!heapG Σ}.
Context `{!ghost_varG Σ (gmap u64 (list u8))}.
Context `{!mapG Σ u64 (list u8)}.
Implicit Types (stk:stuckness) (E: coPset).

Record simple_names := {
  simple_buftxn : buftxn_names Σ;
  simple_buftxn_next : buftxn_names Σ;
  simple_src : gname;
  simple_lockmapghs : list (gen_heapG u64 bool Σ);
}.

Variable P : SimpleNFS.State -> iProp Σ.
Context `{Ptimeless : !forall σ, Timeless (P σ)}.

Definition LogSz : nat := 513.
Definition InodeSz : nat := 128.
Definition NumInodes : nat := 4096 / InodeSz.

Definition covered_inodes : gset u64 :=
  rangeSet 2 (NumInodes-2).

Definition no_overflows (src : SimpleNFS.State) : iProp Σ :=
  ([∗ map] _↦istate ∈ src, ⌜(length istate < 2^64)%Z⌝)%I.

Global Instance no_overflows_Persistent src : Persistent (no_overflows src).
Proof. refine _. Qed.

Definition is_source γ : iProp Σ :=
  ∃ (src: SimpleNFS.State),
    (* If we were doing a refinement proof, the top-level source_state would
     * own 1/2 of this [map_ctx] *)
    "Hsrcheap" ∷ map_ctx γ 1%Qp src ∗
    "%Hdom" ∷ ⌜dom (gset _) src = covered_inodes⌝ ∗
    "#Hnooverflow" ∷ no_overflows src ∗
    "HP" ∷ P src.

Definition encodes_inode (len: u64) (blk: u64) data : Prop :=
  has_encoding data (EncUInt64 len :: EncUInt64 blk :: nil).

Definition inum2addr (inum : u64) := Build_addr LogSz (int.nat inum * InodeSz * 8).
Definition blk2addr blk := Build_addr blk 0.

Definition is_inode_enc (inum: u64) (len: u64) (blk: u64) (mapsto: addr -> object -> iProp Σ) : iProp Σ :=
  ∃ (ibuf : defs.inode_buf),
    "%Hinode_encodes" ∷ ⌜ encodes_inode len blk (vec_to_list ibuf) ⌝ ∗
    "Hinode_enc_mapsto" ∷ mapsto (inum2addr inum) (existT _ (defs.bufInode ibuf)).

Definition is_inode_data (len : u64) (blk: u64) (contents: list u8) (mapsto: addr -> object -> iProp Σ) : iProp Σ :=
  ∃ (bbuf : Block),
    "%Hdiskdata" ∷ ⌜ firstn (length contents) (vec_to_list bbuf) = contents ⌝ ∗
    "%Hdisklen" ∷ ⌜ int.Z len = length contents ⌝ ∗
    "Hdiskblk" ∷ mapsto (blk2addr blk) (existT _ (defs.bufBlock bbuf)).

Definition is_inode (inum: u64) (state: list u8) (mapsto: addr -> object -> iProp Σ) : iProp Σ :=
  ∃ (blk: u64),
    "Hinode_enc" ∷ is_inode_enc inum (length state) blk mapsto ∗
    "Hinode_data" ∷ is_inode_data (length state) blk state mapsto.

Definition is_inode_mem (l: loc) (inum: u64) (len: u64) (blk: u64) : iProp Σ :=
  "Hinum" ∷ l ↦[Inode.S :: "Inum"] #inum ∗
  "Hisize" ∷ l ↦[Inode.S :: "Size"] #len ∗
  "Hidata" ∷ l ↦[Inode.S :: "Data"] #blk.

Definition Nbuftxn := nroot .@ "buftxn".

Definition is_inode_stable γsrc γtxn (inum: u64) : iProp Σ :=
  ∃ (state: list u8),
    "Hinode_state" ∷ inum [[γsrc]]↦ state ∗
    "Hinode_disk" ∷ is_inode inum state (durable_mapsto_own γtxn).

Definition N := nroot .@ "simplenfs".

Definition is_fh (s : Slice.t) (fh : u64) : iProp Σ :=
  ∃ vs,
    "#Hfh_slice" ∷ readonly (is_slice_small s u8T 1 vs) ∗
    "%Hfh_enc" ∷ ⌜ has_encoding vs (EncUInt64 fh :: nil) ⌝.

Definition is_fs γ (nfs: loc) dinit : iProp Σ :=
  ∃ (txn lm : loc),
    "#Hfs_txn" ∷ readonly (nfs ↦[Nfs.S :: "t"] #txn) ∗
    "#Hfs_lm" ∷ readonly (nfs ↦[Nfs.S :: "l"] #lm) ∗
    "#Histxn" ∷ is_txn txn γ.(simple_buftxn).(buftxn_txn_names) dinit ∗
    "#Hislm" ∷ is_crash_lockMap 10 lm γ.(simple_lockmapghs) covered_inodes
                                (is_inode_stable γ.(simple_src) γ.(simple_buftxn))
                                (is_inode_stable γ.(simple_src) γ.(simple_buftxn_next)) ∗
    "#Hsrc" ∷ inv N (is_source γ.(simple_src)) ∗
    "#Htxnsys" ∷ is_txn_system Nbuftxn γ.(simple_buftxn) ∗
    "#Htxncrash" ∷ txn_cinv Nbuftxn γ.(simple_buftxn) γ.(simple_buftxn_next).

Global Instance is_fs_persistent γ nfs dinit : Persistent (is_fs γ nfs dinit).
Proof. apply _. Qed.

End heap.
