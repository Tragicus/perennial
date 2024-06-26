(* autogenerated from github.com/mit-pdos/gokv/fencing/config *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.urpc.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* client.go *)

Definition RPC_ACQUIRE_EPOCH : expr := #0.

Definition RPC_GET : expr := #1.

Definition RPC_HB : expr := #2.

Definition Clerk := struct.decl [
  "cl" :: ptrT
].

(* TIMEOUT_MS from server.go *)

Definition TIMEOUT_MS : expr := #1000.

Definition MILLION : expr := #1000000.

Definition Clerk__HeartbeatThread: val :=
  rec: "Clerk__HeartbeatThread" "ck" "epoch" :=
    let: "enc" := marshal.NewEnc #8 in
    marshal.Enc__PutInt "enc" "epoch";;
    let: "args" := marshal.Enc__Finish "enc" in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
      time.Sleep ((TIMEOUT_MS * MILLION) `quot` #3);;
      let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_HB "args" "reply_ptr" #100 in
      (if: ("err" ≠ #0) || ((slice.len (![slice.T byteT] "reply_ptr")) ≠ #0)
      then Break
      else Continue));;
    #().

Definition Clerk__AcquireEpoch: val :=
  rec: "Clerk__AcquireEpoch" "ck" "newFrontend" :=
    let: "enc" := marshal.NewEnc #8 in
    marshal.Enc__PutInt "enc" "newFrontend";;
    let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_ACQUIRE_EPOCH (marshal.Enc__Finish "enc") "reply_ptr" #100 in
    (if: "err" ≠ #0
    then
      (* log.Println("config: client failed to run RPC on config server") *)
      control.impl.Exit #1
    else #());;
    let: "dec" := marshal.NewDec (![slice.T byteT] "reply_ptr") in
    marshal.Dec__GetInt "dec".

Definition Clerk__Get: val :=
  rec: "Clerk__Get" "ck" :=
    let: "reply_ptr" := ref (zero_val (slice.T byteT)) in
    let: "err" := urpc.Client__Call (struct.loadF Clerk "cl" "ck") RPC_GET (NewSlice byteT #0) "reply_ptr" #100 in
    (if: "err" ≠ #0
    then
      (* log.Println("config: client failed to run RPC on config server") *)
      control.impl.Exit #1
    else #());;
    let: "dec" := marshal.NewDec (![slice.T byteT] "reply_ptr") in
    marshal.Dec__GetInt "dec".

Definition MakeClerk: val :=
  rec: "MakeClerk" "host" :=
    let: "ck" := struct.alloc Clerk (zero_val (struct.t Clerk)) in
    struct.storeF Clerk "cl" "ck" (urpc.MakeClient "host");;
    "ck".

(* server.go *)

Definition Server := struct.decl [
  "mu" :: ptrT;
  "data" :: uint64T;
  "currentEpoch" :: uint64T;
  "epoch_cond" :: ptrT;
  "currHolderActive" :: boolT;
  "currHolderActive_cond" :: ptrT;
  "heartbeatExpiration" :: uint64T
].

Definition Server__AcquireEpoch: val :=
  rec: "Server__AcquireEpoch" "s" "newFrontend" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    Skip;;
    (for: (λ: <>, struct.loadF Server "currHolderActive" "s"); (λ: <>, Skip) := λ: <>,
      lock.condWait (struct.loadF Server "currHolderActive_cond" "s");;
      Continue);;
    struct.storeF Server "currHolderActive" "s" #true;;
    struct.storeF Server "data" "s" "newFrontend";;
    struct.storeF Server "currentEpoch" "s" ((struct.loadF Server "currentEpoch" "s") + #1);;
    let: "now" := time.TimeNow #() in
    struct.storeF Server "heartbeatExpiration" "s" ("now" + (TIMEOUT_MS * MILLION));;
    let: "ret" := struct.loadF Server "currentEpoch" "s" in
    lock.release (struct.loadF Server "mu" "s");;
    "ret".

Definition Server__HeartbeatListener: val :=
  rec: "Server__HeartbeatListener" "s" :=
    let: "epochToWaitFor" := ref_to uint64T #1 in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      lock.acquire (struct.loadF Server "mu" "s");;
      Skip;;
      (for: (λ: <>, (struct.loadF Server "currentEpoch" "s") < (![uint64T] "epochToWaitFor")); (λ: <>, Skip) := λ: <>,
        lock.condWait (struct.loadF Server "epoch_cond" "s");;
        Continue);;
      lock.release (struct.loadF Server "mu" "s");;
      Skip;;
      (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
        let: "now" := time.TimeNow #() in
        lock.acquire (struct.loadF Server "mu" "s");;
        (if: "now" < (struct.loadF Server "heartbeatExpiration" "s")
        then
          let: "delay" := (struct.loadF Server "heartbeatExpiration" "s") - "now" in
          lock.release (struct.loadF Server "mu" "s");;
          time.Sleep "delay";;
          Continue
        else
          struct.storeF Server "currHolderActive" "s" #false;;
          lock.condSignal (struct.loadF Server "currHolderActive_cond" "s");;
          "epochToWaitFor" <-[uint64T] ((struct.loadF Server "currentEpoch" "s") + #1);;
          lock.release (struct.loadF Server "mu" "s");;
          Break));;
      Continue);;
    #().

(* returns true iff successful *)
Definition Server__Heartbeat: val :=
  rec: "Server__Heartbeat" "s" "epoch" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    let: "ret" := ref_to boolT #false in
    (if: (struct.loadF Server "currentEpoch" "s") = "epoch"
    then
      let: "now" := time.TimeNow #() in
      struct.storeF Server "heartbeatExpiration" "s" ("now" + TIMEOUT_MS);;
      "ret" <-[boolT] #true
    else #());;
    lock.release (struct.loadF Server "mu" "s");;
    ![boolT] "ret".

(* XXX: don't need to send fencing token here, because client won't need it *)
Definition Server__Get: val :=
  rec: "Server__Get" "s" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    let: "ret" := struct.loadF Server "data" "s" in
    lock.release (struct.loadF Server "mu" "s");;
    "ret".

Definition StartServer: val :=
  rec: "StartServer" "me" :=
    let: "s" := struct.alloc Server (zero_val (struct.t Server)) in
    struct.storeF Server "mu" "s" (lock.new #());;
    struct.storeF Server "data" "s" #0;;
    struct.storeF Server "currentEpoch" "s" #0;;
    struct.storeF Server "epoch_cond" "s" (lock.newCond (struct.loadF Server "mu" "s"));;
    struct.storeF Server "currHolderActive" "s" #false;;
    struct.storeF Server "currHolderActive_cond" "s" (lock.newCond (struct.loadF Server "mu" "s"));;
    Fork (Server__HeartbeatListener "s");;
    let: "handlers" := NewMap uint64T ((slice.T byteT) -> ptrT -> unitT)%ht #() in
    MapInsert "handlers" RPC_ACQUIRE_EPOCH (λ: "args" "reply",
      let: "dec" := marshal.NewDec "args" in
      let: "enc" := marshal.NewEnc #8 in
      marshal.Enc__PutInt "enc" (Server__AcquireEpoch "s" (marshal.Dec__GetInt "dec"));;
      "reply" <-[slice.T byteT] (marshal.Enc__Finish "enc");;
      #()
      );;
    MapInsert "handlers" RPC_GET (λ: "args" "reply",
      let: "enc" := marshal.NewEnc #8 in
      marshal.Enc__PutInt "enc" (Server__Get "s");;
      "reply" <-[slice.T byteT] (marshal.Enc__Finish "enc");;
      #()
      );;
    MapInsert "handlers" RPC_HB (λ: "args" "reply",
      let: "dec" := marshal.NewDec "args" in
      (if: Server__Heartbeat "s" (marshal.Dec__GetInt "dec")
      then
        "reply" <-[slice.T byteT] (NewSlice byteT #0);;
        #()
      else
        "reply" <-[slice.T byteT] (NewSlice byteT #1);;
        #())
      );;
    let: "r" := urpc.MakeServer "handlers" in
    urpc.Server__Serve "r" "me";;
    #().
