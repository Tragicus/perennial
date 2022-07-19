(* autogenerated from github.com/mit-pdos/go-mvcc/txn *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.go_mvcc.common.
From Goose Require github_com.mit_pdos.go_mvcc.config.
From Goose Require github_com.mit_pdos.go_mvcc.gc.
From Goose Require github_com.mit_pdos.go_mvcc.index.
From Goose Require github_com.mit_pdos.go_mvcc.wrbuf.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition Txn := struct.decl [
  "tid" :: uint64T;
  "sid" :: uint64T;
  "wrbuf" :: ptrT;
  "idx" :: ptrT;
  "txnMgr" :: ptrT
].

Definition TxnSite := struct.decl [
  "latch" :: ptrT;
  "tidLast" :: uint64T;
  "tidsActive" :: slice.T uint64T;
  "padding" :: arrayT uint64T
].

Definition TxnMgr := struct.decl [
  "latch" :: ptrT;
  "sidCur" :: uint64T;
  "sites" :: slice.T ptrT;
  "idx" :: ptrT;
  "gc" :: ptrT;
  "p" :: ProphIdT
].

Definition MkTxnMgr: val :=
  rec: "MkTxnMgr" <> :=
    let: "txnMgr" := struct.alloc TxnMgr (zero_val (struct.t TxnMgr)) in
    struct.storeF TxnMgr "latch" "txnMgr" (lock.new #());;
    struct.storeF TxnMgr "sites" "txnMgr" (NewSlice ptrT config.N_TXN_SITES);;
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < config.N_TXN_SITES); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      let: "site" := struct.alloc TxnSite (zero_val (struct.t TxnSite)) in
      struct.storeF TxnSite "latch" "site" (lock.new #());;
      struct.storeF TxnSite "tidsActive" "site" (NewSliceWithCap uint64T #0 #8);;
      SliceSet ptrT (struct.loadF TxnMgr "sites" "txnMgr") (![uint64T] "i") "site";;
      Continue);;
    struct.storeF TxnMgr "idx" "txnMgr" (index.MkIndex #());;
    struct.storeF TxnMgr "gc" "txnMgr" (gc.MkGC (struct.loadF TxnMgr "idx" "txnMgr"));;
    "txnMgr".

Definition TxnMgr__New: val :=
  rec: "TxnMgr__New" "txnMgr" :=
    lock.acquire (struct.loadF TxnMgr "latch" "txnMgr");;
    let: "txn" := struct.alloc Txn (zero_val (struct.t Txn)) in
    let: "sid" := struct.loadF TxnMgr "sidCur" "txnMgr" in
    struct.storeF Txn "sid" "txn" "sid";;
    struct.storeF Txn "idx" "txn" (struct.loadF TxnMgr "idx" "txnMgr");;
    struct.storeF Txn "txnMgr" "txn" "txnMgr";;
    struct.storeF TxnMgr "sidCur" "txnMgr" ("sid" + #1);;
    (if: struct.loadF TxnMgr "sidCur" "txnMgr" ≥ config.N_TXN_SITES
    then struct.storeF TxnMgr "sidCur" "txnMgr" #0
    else #());;
    lock.release (struct.loadF TxnMgr "latch" "txnMgr");;
    "txn".

Definition genTID: val :=
  rec: "genTID" "sid" :=
    let: "tid" := ref (zero_val uint64T) in
    "tid" <-[uint64T] grove_ffi.GetTSC #();;
    "tid" <-[uint64T] (![uint64T] "tid" + config.N_TXN_SITES `and` ~ (config.N_TXN_SITES - #1)) + "sid";;
    Skip;;
    (for: (λ: <>, grove_ffi.GetTSC #() ≤ ![uint64T] "tid"); (λ: <>, Skip) := λ: <>,
      Continue);;
    ![uint64T] "tid".

Definition TxnMgr__activate: val :=
  rec: "TxnMgr__activate" "txnMgr" "sid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "tid" := ref (zero_val uint64T) in
    "tid" <-[uint64T] genTID "sid";;
    Skip;;
    (for: (λ: <>, ![uint64T] "tid" ≤ struct.loadF TxnSite "tidLast" "site"); (λ: <>, Skip) := λ: <>,
      "tid" <-[uint64T] genTID "sid";;
      Continue);;
    control.impl.Assume (![uint64T] "tid" < #18446744073709551615);;
    struct.storeF TxnSite "tidLast" "site" (![uint64T] "tid");;
    struct.storeF TxnSite "tidsActive" "site" (SliceAppend uint64T (struct.loadF TxnSite "tidsActive" "site") (![uint64T] "tid"));;
    lock.release (struct.loadF TxnSite "latch" "site");;
    ![uint64T] "tid".

Definition findTID: val :=
  rec: "findTID" "tid" "tids" :=
    let: "idx" := ref_to uint64T #0 in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "tidx" := SliceGet uint64T "tids" (![uint64T] "idx") in
      (if: ("tid" = "tidx")
      then Break
      else
        "idx" <-[uint64T] ![uint64T] "idx" + #1;;
        Continue));;
    ![uint64T] "idx".

(* *
    * Precondition:
    * 1. `xs` not empty.
    * 2. `i < len(xs)` *)
Definition swapWithEnd: val :=
  rec: "swapWithEnd" "xs" "i" :=
    let: "tmp" := SliceGet uint64T "xs" (slice.len "xs" - #1) in
    SliceSet uint64T "xs" (slice.len "xs" - #1) (SliceGet uint64T "xs" "i");;
    SliceSet uint64T "xs" "i" "tmp";;
    #().

(* *
    * This function is called by `Txn` at commit/abort time.
    * Precondition:
    * 1. The set of active transactions contains `tid`. *)
Definition TxnMgr__deactivate: val :=
  rec: "TxnMgr__deactivate" "txnMgr" "sid" "tid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "idx" := findTID "tid" (struct.loadF TxnSite "tidsActive" "site") in
    swapWithEnd (struct.loadF TxnSite "tidsActive" "site") "idx";;
    struct.storeF TxnSite "tidsActive" "site" (SliceTake (struct.loadF TxnSite "tidsActive" "site") (slice.len (struct.loadF TxnSite "tidsActive" "site") - #1));;
    lock.release (struct.loadF TxnSite "latch" "site");;
    #().

Definition TxnMgr__getMinActiveTIDSite: val :=
  rec: "TxnMgr__getMinActiveTIDSite" "txnMgr" "sid" :=
    let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") "sid" in
    lock.acquire (struct.loadF TxnSite "latch" "site");;
    let: "tidnew" := ref (zero_val uint64T) in
    "tidnew" <-[uint64T] genTID "sid";;
    Skip;;
    (for: (λ: <>, ![uint64T] "tidnew" ≤ struct.loadF TxnSite "tidLast" "site"); (λ: <>, Skip) := λ: <>,
      "tidnew" <-[uint64T] genTID "sid";;
      Continue);;
    struct.storeF TxnSite "tidLast" "site" (![uint64T] "tidnew");;
    let: "tidmin" := ref_to uint64T (![uint64T] "tidnew") in
    ForSlice uint64T <> "tid" (struct.loadF TxnSite "tidsActive" "site")
      (if: "tid" < ![uint64T] "tidmin"
      then "tidmin" <-[uint64T] "tid"
      else #());;
    lock.release (struct.loadF TxnSite "latch" "site");;
    ![uint64T] "tidmin".

(* *
    * This function returns a lower bound of the active TID. *)
Definition TxnMgr__getMinActiveTID: val :=
  rec: "TxnMgr__getMinActiveTID" "txnMgr" :=
    let: "min" := ref_to uint64T config.TID_SENTINEL in
    let: "sid" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "sid" < config.N_TXN_SITES); (λ: <>, "sid" <-[uint64T] ![uint64T] "sid" + #1) := λ: <>,
      let: "tid" := TxnMgr__getMinActiveTIDSite "txnMgr" (![uint64T] "sid") in
      (if: "tid" < ![uint64T] "min"
      then
        "min" <-[uint64T] "tid";;
        Continue
      else Continue));;
    ![uint64T] "min".

(* *
    * Probably only used for testing and profiling. *)
Definition TxnMgr__getNumActiveTxns: val :=
  rec: "TxnMgr__getNumActiveTxns" "txnMgr" :=
    let: "n" := ref_to uint64T #0 in
    let: "sid" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "sid" < config.N_TXN_SITES); (λ: <>, "sid" <-[uint64T] ![uint64T] "sid" + #1) := λ: <>,
      let: "site" := SliceGet ptrT (struct.loadF TxnMgr "sites" "txnMgr") (![uint64T] "sid") in
      lock.acquire (struct.loadF TxnSite "latch" "site");;
      "n" <-[uint64T] ![uint64T] "n" + slice.len (struct.loadF TxnSite "tidsActive" "site");;
      lock.release (struct.loadF TxnSite "latch" "site");;
      Continue);;
    ![uint64T] "n".

Definition TxnMgr__runGC: val :=
  rec: "TxnMgr__runGC" "txnMgr" :=
    let: "tidMin" := TxnMgr__getMinActiveTID "txnMgr" in
    (if: "tidMin" < config.TID_SENTINEL
    then
      gc.GC__Start (struct.loadF TxnMgr "gc" "txnMgr") "tidMin";;
      #()
    else #()).

Definition TxnMgr__StartGC: val :=
  rec: "TxnMgr__StartGC" "txnMgr" :=
    Fork (Skip;;
          (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
            TxnMgr__runGC "txnMgr";;
            Continue));;
    #().

Definition Txn__Put: val :=
  rec: "Txn__Put" "txn" "key" "val" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    wrbuf.WrBuf__Put "wrbuf" "key" "val";;
    let: "idx" := struct.loadF Txn "idx" "txn" in
    let: "tuple" := index.Index__GetTuple "idx" "key" in
    let: "ret" := tuple.Tuple__Own "tuple" (struct.loadF Txn "tid" "txn") in
    (if: "ret" ≠ common.RET_SUCCESS
    then #false
    else #true).

Definition Txn__Delete: val :=
  rec: "Txn__Delete" "txn" "key" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    wrbuf.WrBuf__Delete "wrbuf" "key";;
    let: "idx" := struct.loadF Txn "idx" "txn" in
    let: "tuple" := index.Index__GetTuple "idx" "key" in
    let: "ret" := tuple.Tuple__Own "tuple" (struct.loadF Txn "tid" "txn") in
    (if: "ret" ≠ common.RET_SUCCESS
    then #false
    else #true).

Definition Txn__Get: val :=
  rec: "Txn__Get" "txn" "key" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    let: (("valb", "del"), "found") := wrbuf.WrBuf__Lookup "wrbuf" "key" in
    (if: "found"
    then ("valb", ~ "del")
    else
      let: "idx" := struct.loadF Txn "idx" "txn" in
      let: "tuple" := index.Index__GetTuple "idx" "key" in
      let: ("val", "ret") := tuple.Tuple__ReadVersion "tuple" (struct.loadF Txn "tid" "txn") in
      ("val", ("ret" = common.RET_SUCCESS))).

Definition Txn__Begin: val :=
  rec: "Txn__Begin" "txn" :=
    let: "tid" := TxnMgr__activate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") in
    struct.storeF Txn "tid" "txn" "tid";;
    wrbuf.WrBuf__Clear (struct.loadF Txn "wrbuf" "txn");;
    #().

Definition Txn__Commit: val :=
  rec: "Txn__Commit" "txn" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < wrbuf.WrBuf__Len "wrbuf"); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      let: (("key", "val"), "del") := wrbuf.WrBuf__GetEntAt "wrbuf" (![uint64T] "i") in
      let: "idx" := struct.loadF Txn "idx" "txn" in
      let: "tuple" := index.Index__GetTuple "idx" "key" in
      (if: "del"
      then
        tuple.Tuple__KillVersion "tuple" (struct.loadF Txn "tid" "txn");;
        Continue
      else
        tuple.Tuple__AppendVersion "tuple" (struct.loadF Txn "tid" "txn") "val";;
        Continue));;
    TxnMgr__deactivate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") (struct.loadF Txn "tid" "txn");;
    #().

Definition Txn__Abort: val :=
  rec: "Txn__Abort" "txn" :=
    let: "wrbuf" := struct.loadF Txn "wrbuf" "txn" in
    let: "i" := ref_to uint64T #0 in
    (for: (λ: <>, ![uint64T] "i" < wrbuf.WrBuf__Len "wrbuf"); (λ: <>, "i" <-[uint64T] ![uint64T] "i" + #1) := λ: <>,
      let: (("key", <>), <>) := wrbuf.WrBuf__GetEntAt "wrbuf" (![uint64T] "i") in
      let: "idx" := struct.loadF Txn "idx" "txn" in
      let: "tuple" := index.Index__GetTuple "idx" "key" in
      tuple.Tuple__Free "tuple" (struct.loadF Txn "tid" "txn");;
      Continue);;
    TxnMgr__deactivate (struct.loadF Txn "txnMgr" "txn") (struct.loadF Txn "sid" "txn") (struct.loadF Txn "tid" "txn");;
    #().
