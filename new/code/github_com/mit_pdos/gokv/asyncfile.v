(* autogenerated from github.com/mit-pdos/gokv/asyncfile *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.std.
From New.code Require github_com.mit_pdos.gokv.grove_ffi.
From New.code Require sync.

From New Require Import grove_prelude.

Definition AsyncFile : go_type := structT [
  "mu" :: ptrT;
  "data" :: sliceT;
  "filename" :: stringT;
  "index" :: uint64T;
  "indexCond" :: ptrT;
  "durableIndex" :: uint64T;
  "durableIndexCond" :: ptrT;
  "closeRequested" :: boolT;
  "closed" :: boolT;
  "closedCond" :: ptrT
].

Definition AsyncFile__mset : list (string * val) := [
].

(* go: storage.go:73:21 *)
Definition AsyncFile__Close : val :=
  rec: "AsyncFile__Close" "s" <> :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    let: "$r0" := #true in
    do:  ((struct.field_ref AsyncFile "closeRequested" (![ptrT] "s")) <-[boolT] "$r0");;;
    do:  ((sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
    (for: (λ: <>, (~ (![boolT] (struct.field_ref AsyncFile "closed" (![ptrT] "s"))))); (λ: <>, Skip) := λ: <>,
      do:  ((sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #()))).

(* go: storage.go:36:21 *)
Definition AsyncFile__wait : val :=
  rec: "AsyncFile__wait" "s" "index" :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    let: "index" := (ref_ty uint64T "index") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    (for: (λ: <>, (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) < (![uint64T] "index")); (λ: <>, Skip) := λ: <>,
      do:  ((sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #()))).

(* go: storage.go:24:21 *)
Definition AsyncFile__Write : val :=
  rec: "AsyncFile__Write" "s" "data" :=
    with_defer: (let: "s" := (ref_ty ptrT "s") in
    let: "data" := (ref_ty sliceT "data") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    do:  (let: "$f" := (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) in
    "$defer" <-[funcT] (let: "$oldf" := (![funcT] "$defer") in
    (λ: <>,
      "$f" #();;
      "$oldf" #()
      )));;;
    let: "$r0" := (![sliceT] "data") in
    do:  ((struct.field_ref AsyncFile "data" (![ptrT] "s")) <-[sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
    let: "$a1" := #(W64 1) in
    std.SumAssumeNoOverflow "$a0" "$a1") in
    do:  ((struct.field_ref AsyncFile "index" (![ptrT] "s")) <-[uint64T] "$r0");;;
    let: "index" := (ref_ty uint64T (zero_val uint64T)) in
    let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
    do:  ("index" <-[uint64T] "$r0");;;
    do:  ((sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
    return: ((λ: <>,
       exception_do (do:  (let: "$a0" := (![uint64T] "index") in
       (AsyncFile__wait (![ptrT] "s")) "$a0"))
       ))).

(* go: storage.go:45:21 *)
Definition AsyncFile__flushThread : val :=
  rec: "AsyncFile__flushThread" "s" <> :=
    exception_do (let: "s" := (ref_ty ptrT "s") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      (if: ![boolT] (struct.field_ref AsyncFile "closeRequested" (![ptrT] "s"))
      then
        do:  (let: "$a0" := (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) in
        let: "$a1" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
        grove_ffi.FileWrite "$a0" "$a1");;;
        let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
        do:  ((struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$r0");;;
        do:  ((sync.Cond__Broadcast (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #());;;
        let: "$r0" := #true in
        do:  ((struct.field_ref AsyncFile "closed" (![ptrT] "s")) <-[boolT] "$r0");;;
        do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
        do:  ((sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #());;;
        return: (#())
      else do:  #());;;
      (if: (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) ≥ (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")))
      then
        do:  ((sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #());;;
        continue: #()
      else do:  #());;;
      let: "index" := (ref_ty uint64T (zero_val uint64T)) in
      let: "$r0" := (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) in
      do:  ("index" <-[uint64T] "$r0");;;
      let: "data" := (ref_ty sliceT (zero_val sliceT)) in
      let: "$r0" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
      do:  ("data" <-[sliceT] "$r0");;;
      do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
      do:  (let: "$a0" := (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) in
      let: "$a1" := (![sliceT] "data") in
      grove_ffi.FileWrite "$a0" "$a1");;;
      do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #());;;
      let: "$r0" := (![uint64T] "index") in
      do:  ((struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$r0");;;
      do:  ((sync.Cond__Broadcast (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #()))).

Definition AsyncFile__mset_ptr : list (string * val) := [
  ("Close", AsyncFile__Close%V);
  ("Write", AsyncFile__Write%V);
  ("flushThread", AsyncFile__flushThread%V);
  ("wait", AsyncFile__wait%V)
].

(* returns the state, then the File object

   go: storage.go:85:6 *)
Definition MakeAsyncFile : val :=
  rec: "MakeAsyncFile" "filename" :=
    exception_do (let: "filename" := (ref_ty stringT "filename") in
    let: "mu" := (ref_ty sync.Mutex (zero_val sync.Mutex)) in
    let: "s" := (ref_ty ptrT (zero_val ptrT)) in
    let: "$r0" := (ref_ty AsyncFile (let: "mu" := "mu" in
    let: "indexCond" := (let: "$a0" := (interface.make sync.Mutex__mset_ptr "mu") in
    sync.NewCond "$a0") in
    let: "closedCond" := (let: "$a0" := (interface.make sync.Mutex__mset_ptr "mu") in
    sync.NewCond "$a0") in
    let: "durableIndexCond" := (let: "$a0" := (interface.make sync.Mutex__mset_ptr "mu") in
    sync.NewCond "$a0") in
    let: "filename" := (![stringT] "filename") in
    let: "data" := (let: "$a0" := (![stringT] "filename") in
    grove_ffi.FileRead "$a0") in
    let: "index" := #(W64 0) in
    let: "durableIndex" := #(W64 0) in
    let: "closed" := #false in
    let: "closeRequested" := #false in
    struct.make AsyncFile [{
      "mu" ::= "mu";
      "data" ::= "data";
      "filename" ::= "filename";
      "index" ::= "index";
      "indexCond" ::= "indexCond";
      "durableIndex" ::= "durableIndex";
      "durableIndexCond" ::= "durableIndexCond";
      "closeRequested" ::= "closeRequested";
      "closed" ::= "closed";
      "closedCond" ::= "closedCond"
    }])) in
    do:  ("s" <-[ptrT] "$r0");;;
    let: "data" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (![sliceT] (struct.field_ref AsyncFile "data" (![ptrT] "s"))) in
    do:  ("data" <-[sliceT] "$r0");;;
    let: "$go" := (AsyncFile__flushThread (![ptrT] "s")) in
    do:  (Fork ("$go" #()));;;
    return: (![sliceT] "data", ![ptrT] "s")).
