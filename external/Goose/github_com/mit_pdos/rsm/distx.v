(* autogenerated from github.com/mit-pdos/rsm/distx *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

Definition Value := struct.decl [
  "b" :: boolT;
  "s" :: stringT
].

Definition WriteEntry := struct.decl [
  "k" :: stringT;
  "v" :: struct.t Value
].

Definition N_SHARDS : expr := #2.

(* @ts
   Starting timestamp of this version, and also ending timestamp of the next
   version. Lifetime is a half-open interval: [ts of this, ts of next).

   @val
   Value of this version. *)
Definition Version := struct.decl [
  "ts" :: uint64T;
  "val" :: struct.t Value
].

Definition Tuple__Own: val :=
  rec: "Tuple__Own" "tuple" "tid" :=
    #false.

Definition Tuple__ReadVersion: val :=
  rec: "Tuple__ReadVersion" "tuple" "tid" :=
    (struct.mk Value [
     ], #false).

Definition Tuple__Extend: val :=
  rec: "Tuple__Extend" "tuple" "tid" :=
    #false.

Definition Tuple__AppendVersion: val :=
  rec: "Tuple__AppendVersion" "tuple" "tid" "val" :=
    #().

Definition Tuple__KillVersion: val :=
  rec: "Tuple__KillVersion" "tuple" "tid" :=
    #().

Definition Tuple__Free: val :=
  rec: "Tuple__Free" "tuple" :=
    #().

(* @owned
   Write lock of this tuple. Acquired before committing.

   @tslast
   Timestamp of the last reader or last writer + 1.

   @vers
   Versions. *)
Definition Tuple := struct.decl [
  "latch" :: ptrT;
  "owned" :: boolT;
  "tslast" :: uint64T;
  "vers" :: slice.T (struct.t Version)
].

Definition Index := struct.decl [
].

Definition Index__GetTuple: val :=
  rec: "Index__GetTuple" "idx" "key" :=
    struct.new Tuple [
    ].

Definition Cmd := struct.decl [
  "kind" :: uint64T;
  "ts" :: uint64T;
  "wrs" :: slice.T (struct.t WriteEntry);
  "key" :: stringT
].

Definition TxnLog := struct.decl [
].

(* Arguments:
   @ts: Transaction timestamp.

   @wrs: Transaction write set.

   Return values:
   @lsn (uint64): @lsn = 0 indicates failure; otherwise, this indicates the
   logical index this command is supposed to be placed at.

   @term (uint64): The @term this command is supposed to have.

   Notes:
   1) Passing @lsn and @term to @WaitUntilSafe allows us to determine whether
   the command we just submitted actually get safely replicated (and wait until
   that happens up to some timeout).

   2) Although @term is redundant in that we can always detect failure by
   comparing the content of the command to some application state (e.g., a reply
   table), it can be seen as a performance optimization that would allow us to
   know earlier that our command has not been safely replicated (and hence
   resubmit). Another upside of having it would be that this allows the check to
   be done in a general way, without relying on the content. *)
Definition TxnLog__SubmitPrepare: val :=
  rec: "TxnLog__SubmitPrepare" "log" "ts" "wrs" :=
    (#0, #0).

(* Arguments:
   @ts: Transaction timestamp.

   @key: Key to be read.

   Return values: see description of @SubmitPrepare. *)
Definition TxnLog__SubmitRead: val :=
  rec: "TxnLog__SubmitRead" "log" "ts" "key" :=
    (#0, #0).

(* Arguments and return values: see description of @SubmitPrepare. *)
Definition TxnLog__SubmitCommit: val :=
  rec: "TxnLog__SubmitCommit" "log" "ts" :=
    (#0, #0).

(* Arguments and return values: see description of @SubmitPrepare. *)
Definition TxnLog__SubmitAbort: val :=
  rec: "TxnLog__SubmitAbort" "log" "ts" :=
    (#0, #0).

(* Arguments:
   @lsn: LSN of the command whose replication to wait for.

   @term: Expected term of the command.

   Return values:
   @replicated (bool): If @true, then the command at @lsn has term @term;
   otherwise, we know nothing, but the upper layer is suggested to resubmit the
   command.

   TODO: maybe this is a bad interface since now the users would have to make
   another call. *)
Definition TxnLog__WaitUntilSafe: val :=
  rec: "TxnLog__WaitUntilSafe" "log" "lsn" "term" :=
    #false.

(* Argument:
   @lsn: Logical index of the queried command. *)
Definition TxnLog__Lookup: val :=
  rec: "TxnLog__Lookup" "log" "lsn" :=
    (struct.mk Cmd [
     ], #false).

Definition Replica := struct.decl [
  "mu" :: ptrT;
  "rid" :: uint64T;
  "log" :: ptrT;
  "lsna" :: uint64T;
  "prepm" :: mapT (slice.T (struct.t WriteEntry));
  "txntbl" :: mapT boolT;
  "idx" :: ptrT;
  "kvmap" :: mapT ptrT
].

Definition Replica__waitUntilExec: val :=
  rec: "Replica__waitUntilExec" "rp" "lsn" :=
    #().

Definition TXN_RUNNING : expr := #0.

Definition TXN_PREPARED : expr := #1.

Definition TXN_ABORTED : expr := #2.

Definition TXN_COMMITTED : expr := #3.

(* Arguments:
   @ts: Transaction timestamp.

   @wrs: Transaction write set.

   Return values:
   @status: Transaction status. *)
Definition Replica__queryTxnStatus: val :=
  rec: "Replica__queryTxnStatus" "rp" "ts" :=
    let: ("cmted", "terminated") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "terminated"
    then
      (if: "cmted"
      then TXN_COMMITTED
      else TXN_ABORTED)
    else
      let: (<>, "preped") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
      (if: "preped"
      then TXN_PREPARED
      else TXN_RUNNING)).

(* Arguments:
   @ts: Transaction timestamp.

   @wrs: Transaction write set.

   Return values:
   @status: Transaction status.

   @ok: If @true, @status is meaningful; otherwise, ignore @status. *)
Definition Replica__Prepare: val :=
  rec: "Replica__Prepare" "rp" "ts" "wrs" :=
    lock.acquire (struct.loadF Replica "mu" "rp");;
    let: "status" := Replica__queryTxnStatus "rp" "ts" in
    (if: "status" ≠ TXN_RUNNING
    then
      lock.release (struct.loadF Replica "mu" "rp");;
      ("status", #true)
    else
      let: ("lsn", "term") := TxnLog__SubmitPrepare (struct.loadF Replica "log" "rp") "ts" "wrs" in
      (if: "lsn" = #0
      then
        lock.release (struct.loadF Replica "mu" "rp");;
        (#0, #false)
      else
        let: "safe" := TxnLog__WaitUntilSafe (struct.loadF Replica "log" "rp") "lsn" "term" in
        (if: (~ "safe")
        then
          lock.release (struct.loadF Replica "mu" "rp");;
          (#0, #false)
        else
          Replica__waitUntilExec "rp" "lsn";;
          lock.release (struct.loadF Replica "mu" "rp");;
          (Replica__queryTxnStatus "rp" "ts", #true)))).

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @ok: If @true, this transaction is committed. *)
Definition Replica__Commit: val :=
  rec: "Replica__Commit" "rp" "ts" :=
    lock.acquire (struct.loadF Replica "mu" "rp");;
    let: (<>, "committed") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "committed"
    then
      lock.release (struct.loadF Replica "mu" "rp");;
      #true
    else
      let: ("lsn", "term") := TxnLog__SubmitCommit (struct.loadF Replica "log" "rp") "ts" in
      (if: "lsn" = #0
      then
        lock.release (struct.loadF Replica "mu" "rp");;
        #false
      else
        let: "safe" := TxnLog__WaitUntilSafe (struct.loadF Replica "log" "rp") "lsn" "term" in
        (if: (~ "safe")
        then
          lock.release (struct.loadF Replica "mu" "rp");;
          #false
        else
          lock.release (struct.loadF Replica "mu" "rp");;
          #true))).

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @ok: If @true, this transaction is aborted. *)
Definition Replica__Abort: val :=
  rec: "Replica__Abort" "rp" "ts" :=
    lock.acquire (struct.loadF Replica "mu" "rp");;
    let: (<>, "aborted") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "aborted"
    then
      lock.release (struct.loadF Replica "mu" "rp");;
      #true
    else
      let: ("lsn", "term") := TxnLog__SubmitAbort (struct.loadF Replica "log" "rp") "ts" in
      (if: "lsn" = #0
      then
        lock.release (struct.loadF Replica "mu" "rp");;
        #false
      else
        let: "safe" := TxnLog__WaitUntilSafe (struct.loadF Replica "log" "rp") "lsn" "term" in
        (if: (~ "safe")
        then
          lock.release (struct.loadF Replica "mu" "rp");;
          #false
        else
          lock.release (struct.loadF Replica "mu" "rp");;
          #true))).

(* Arguments:
   @ts: Transaction timestamp.

   @key: Key to be read.

   Return values:
   @value: Value of the key.

   @ok: @value is meaningful iff @ok is true. *)
Definition Replica__Read: val :=
  rec: "Replica__Read" "rp" "ts" "key" :=
    lock.acquire (struct.loadF Replica "mu" "rp");;
    let: (<>, "terminated") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "terminated"
    then
      lock.release (struct.loadF Replica "mu" "rp");;
      (struct.mk Value [
       ], #false)
    else
      let: ("lsn", "term") := TxnLog__SubmitRead (struct.loadF Replica "log" "rp") "ts" "key" in
      (if: "lsn" = #0
      then
        lock.release (struct.loadF Replica "mu" "rp");;
        (struct.mk Value [
         ], #false)
      else
        let: "safe" := TxnLog__WaitUntilSafe (struct.loadF Replica "log" "rp") "lsn" "term" in
        (if: (~ "safe")
        then
          lock.release (struct.loadF Replica "mu" "rp");;
          (struct.mk Value [
           ], #false)
        else
          Replica__waitUntilExec "rp" "lsn";;
          let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
          let: ("v", "ok") := Tuple__ReadVersion "tpl" "ts" in
          lock.release (struct.loadF Replica "mu" "rp");;
          ("v", "ok")))).

Definition Replica__applyRead: val :=
  rec: "Replica__applyRead" "rp" "ts" "key" :=
    let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
    Tuple__Extend "tpl" "ts";;
    #().

Definition Replica__validate: val :=
  rec: "Replica__validate" "rp" "ts" "wrs" :=
    let: "pos" := ref_to uint64T #0 in
    Skip;;
    (for: (λ: <>, (![uint64T] "pos") < (slice.len "wrs")); (λ: <>, Skip) := λ: <>,
      let: "ent" := SliceGet (struct.t WriteEntry) "wrs" (![uint64T] "pos") in
      let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") (struct.get WriteEntry "k" "ent") in
      let: "ret" := Tuple__Own "tpl" "ts" in
      (if: (~ "ret")
      then Break
      else
        "pos" <-[uint64T] ((![uint64T] "pos") + #1);;
        Continue));;
    (if: (![uint64T] "pos") < (slice.len "wrs")
    then
      let: "ent" := SliceGet (struct.t WriteEntry) "wrs" (![uint64T] "pos") in
      let: "i" := ref_to uint64T #0 in
      Skip;;
      (for: (λ: <>, (![uint64T] "i") < (![uint64T] "pos")); (λ: <>, Skip) := λ: <>,
        let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") (struct.get WriteEntry "k" "ent") in
        Tuple__Free "tpl";;
        "i" <-[uint64T] ((![uint64T] "i") + #1);;
        Continue);;
      #false
    else #true).

Definition Replica__applyPrepare: val :=
  rec: "Replica__applyPrepare" "rp" "ts" "wrs" :=
    let: "status" := Replica__queryTxnStatus "rp" "ts" in
    (if: "status" ≠ TXN_RUNNING
    then #()
    else
      let: "ok" := Replica__validate "rp" "ts" "wrs" in
      (if: (~ "ok")
      then
        MapInsert (struct.loadF Replica "txntbl" "rp") "ts" #false;;
        #()
      else
        MapInsert (struct.loadF Replica "prepm" "rp") "ts" "wrs";;
        #())).

Definition Replica__commit: val :=
  rec: "Replica__commit" "rp" "ts" "wrs" :=
    ForSlice (struct.t WriteEntry) <> "ent" "wrs"
      (let: "key" := struct.get WriteEntry "k" "ent" in
      let: "value" := struct.get WriteEntry "v" "ent" in
      let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
      (if: struct.get Value "b" "value"
      then Tuple__AppendVersion "tpl" "ts" (struct.get Value "s" "value")
      else Tuple__KillVersion "tpl" "ts"));;
    #().

Definition Replica__applyCommit: val :=
  rec: "Replica__applyCommit" "rp" "ts" :=
    let: (<>, "committed") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "committed"
    then #()
    else
      let: "wrs" := Fst (MapGet (struct.loadF Replica "prepm" "rp") "ts") in
      Replica__commit "rp" "ts" "wrs";;
      MapInsert (struct.loadF Replica "txntbl" "rp") "ts" #true;;
      #()).

Definition Replica__abort: val :=
  rec: "Replica__abort" "rp" "wrs" :=
    ForSlice (struct.t WriteEntry) <> "ent" "wrs"
      (let: "key" := struct.get WriteEntry "k" "ent" in
      let: "tpl" := Index__GetTuple (struct.loadF Replica "idx" "rp") "key" in
      Tuple__Free "tpl");;
    #().

Definition Replica__applyAbort: val :=
  rec: "Replica__applyAbort" "rp" "ts" :=
    let: (<>, "aborted") := MapGet (struct.loadF Replica "txntbl" "rp") "ts" in
    (if: "aborted"
    then #()
    else
      let: ("wrs", "prepared") := MapGet (struct.loadF Replica "prepm" "rp") "ts" in
      (if: "prepared"
      then Replica__abort "rp" "wrs"
      else #());;
      MapInsert (struct.loadF Replica "txntbl" "rp") "ts" #false;;
      #()).

Definition Replica__apply: val :=
  rec: "Replica__apply" "rp" "cmd" :=
    (if: (struct.get Cmd "kind" "cmd") = #0
    then
      Replica__applyRead "rp" (struct.get Cmd "ts" "cmd") (struct.get Cmd "key" "cmd");;
      #()
    else
      (if: (struct.get Cmd "kind" "cmd") = #1
      then
        Replica__applyPrepare "rp" (struct.get Cmd "ts" "cmd") (struct.get Cmd "wrs" "cmd");;
        #()
      else
        (if: (struct.get Cmd "kind" "cmd") = #2
        then
          Replica__applyCommit "rp" (struct.get Cmd "ts" "cmd");;
          #()
        else
          Replica__applyAbort "rp" (struct.get Cmd "ts" "cmd");;
          #()))).

Definition Replica__Start: val :=
  rec: "Replica__Start" "rp" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      lock.acquire (struct.loadF Replica "mu" "rp");;
      let: "lsn" := (struct.loadF Replica "lsna" "rp") + #1 in
      let: ("cmd", "ok") := TxnLog__Lookup (struct.loadF Replica "log" "rp") "lsn" in
      (if: (~ "ok")
      then
        lock.release (struct.loadF Replica "mu" "rp");;
        time.Sleep (#1 * #1000000);;
        Continue
      else
        Replica__apply "rp" "cmd";;
        struct.storeF Replica "lsna" "rp" "lsn";;
        Continue));;
    #().

Definition ReplicaGroup := struct.decl [
  "leader" :: uint64T;
  "rps" :: slice.T ptrT;
  "wrs" :: mapT (struct.t Value)
].

Definition ReplicaGroup__changeLeader: val :=
  rec: "ReplicaGroup__changeLeader" "rg" :=
    #().

Definition slicem: val :=
  rec: "slicem" "m" :=
    slice.nil.

(* Arguments:
   @ts: Transaction timestamp.

   Return values:
   @status: Transactin status. *)
Definition ReplicaGroup__Prepare: val :=
  rec: "ReplicaGroup__Prepare" "rg" "ts" :=
    let: "status" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "rp" := SliceGet ptrT (struct.loadF ReplicaGroup "rps" "rg") (struct.loadF ReplicaGroup "leader" "rg") in
      let: ("s", "ok") := Replica__Prepare "rp" "ts" (slicem (struct.loadF ReplicaGroup "wrs" "rg")) in
      (if: "ok"
      then
        "status" <-[uint64T] "s";;
        Break
      else
        ReplicaGroup__changeLeader "rg";;
        Continue));;
    ![uint64T] "status".

Definition ReplicaGroup__Commit: val :=
  rec: "ReplicaGroup__Commit" "rg" "ts" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "rp" := SliceGet ptrT (struct.loadF ReplicaGroup "rps" "rg") (struct.loadF ReplicaGroup "leader" "rg") in
      let: "ok" := Replica__Commit "rp" "ts" in
      (if: "ok"
      then Break
      else
        ReplicaGroup__changeLeader "rg";;
        Continue));;
    #().

Definition ReplicaGroup__Abort: val :=
  rec: "ReplicaGroup__Abort" "rg" "ts" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "rp" := SliceGet ptrT (struct.loadF ReplicaGroup "rps" "rg") (struct.loadF ReplicaGroup "leader" "rg") in
      let: "ok" := Replica__Abort "rp" "ts" in
      (if: "ok"
      then Break
      else
        ReplicaGroup__changeLeader "rg";;
        Continue));;
    #().

Definition Txn := struct.decl [
  "ts" :: uint64T;
  "rgs" :: slice.T (struct.t ReplicaGroup)
].

Definition GetTS: val :=
  rec: "GetTS" <> :=
    #0.

Definition Txn__begin: val :=
  rec: "Txn__begin" "txn" :=
    struct.storeF Txn "ts" "txn" (GetTS #());;
    #().

(* Main proof for this simplified program. *)
Definition Txn__prepare: val :=
  rec: "Txn__prepare" "txn" :=
    let: "status" := ref_to uint64T TXN_PREPARED in
    let: "gid" := ref_to uint64T #0 in
    Skip;;
    (for: (λ: <>, (![uint64T] "gid") < (slice.len (struct.loadF Txn "rgs" "txn"))); (λ: <>, Skip) := λ: <>,
      let: "rg" := SliceGet (struct.t ReplicaGroup) (struct.loadF Txn "rgs" "txn") (![uint64T] "gid") in
      (if: (MapLen (struct.get ReplicaGroup "wrs" "rg")) = #0
      then Continue
      else
        "status" <-[uint64T] (ReplicaGroup__Prepare "rg" (struct.loadF Txn "ts" "txn"));;
        (if: (![uint64T] "status") ≠ TXN_PREPARED
        then Break
        else
          "gid" <-[uint64T] ((![uint64T] "gid") + #1);;
          Continue)));;
    ![uint64T] "status".

Definition Txn__commit: val :=
  rec: "Txn__commit" "txn" :=
    ForSlice (struct.t ReplicaGroup) <> "rg" (struct.loadF Txn "rgs" "txn")
      ((if: (MapLen (struct.get ReplicaGroup "wrs" "rg")) ≠ #0
      then ReplicaGroup__Commit "rg" (struct.loadF Txn "ts" "txn")
      else #()));;
    #().

Definition Txn__abort: val :=
  rec: "Txn__abort" "txn" :=
    ForSlice (struct.t ReplicaGroup) <> "rg" (struct.loadF Txn "rgs" "txn")
      ((if: (MapLen (struct.get ReplicaGroup "wrs" "rg")) ≠ #0
      then ReplicaGroup__Abort "rg" (struct.loadF Txn "ts" "txn")
      else #()));;
    #().

Definition Txn__Read: val :=
  rec: "Txn__Read" "txn" "key" :=
    struct.mk Value [
    ].

Definition Txn__Write: val :=
  rec: "Txn__Write" "txn" "key" "value" :=
    #().

Definition Txn__Delete: val :=
  rec: "Txn__Delete" "txn" "key" :=
    #().

(* Main proof for this simplifed program. *)
Definition Txn__Run: val :=
  rec: "Txn__Run" "txn" "body" :=
    Txn__begin "txn";;
    let: "cmt" := "body" "txn" in
    (if: (~ "cmt")
    then #false
    else
      let: "status" := Txn__prepare "txn" in
      (if: "status" = TXN_COMMITTED
      then #true
      else
        (if: "status" = TXN_ABORTED
        then
          Txn__abort "txn";;
          #false
        else
          Txn__commit "txn";;
          #true))).

Definition NewTxn: val :=
  rec: "NewTxn" <> :=
    struct.new Txn [
    ].

(* Example *)
Definition swap: val :=
  rec: "swap" "txn" :=
    let: "x" := Txn__Read "txn" #(str"0") in
    let: "y" := Txn__Read "txn" #(str"1") in
    Txn__Write "txn" #(str"0") (struct.get Value "s" "y");;
    Txn__Write "txn" #(str"1") (struct.get Value "s" "x");;
    #true.

Definition AtomicSwap: val :=
  rec: "AtomicSwap" <> :=
    let: "txn" := NewTxn #() in
    let: "committed" := Txn__Run "txn" swap in
    "committed".

End code.