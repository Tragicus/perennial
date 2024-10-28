(* autogenerated from github.com/mit-pdos/gokv/cachekv *)
From New.golang Require Import defn.
From New.code Require github_com.mit_pdos.gokv.grove_ffi.
From New.code Require github_com.mit_pdos.gokv.kv.
From New.code Require github_com.tchajed.marshal.
From New.code Require sync.

From New Require Import grove_prelude.

Definition cacheValue : go_type := structT [
  "v" :: stringT;
  "l" :: uint64T
].

Definition cacheValue__mset : list (string * val) := [
].

Definition cacheValue__mset_ptr : list (string * val) := [
].

Definition CacheKv : go_type := structT [
  "kv" :: kv.KvCput;
  "mu" :: ptrT;
  "cache" :: mapT stringT cacheValue
].

Definition CacheKv__mset : list (string * val) := [
].

(* go: clerk.go:24:6 *)
Definition DecodeValue : val :=
  rec: "DecodeValue" "v" :=
    exception_do (let: "v" := (ref_ty stringT "v") in
    let: "e" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (string.to_bytes (![stringT] "v")) in
    do:  ("e" <-[sliceT] "$r0");;;
    let: "vBytes" := (ref_ty sliceT (zero_val sliceT)) in
    let: "l" := (ref_ty uint64T (zero_val uint64T)) in
    let: ("$ret0", "$ret1") := (let: "$a0" := (![sliceT] "e") in
    marshal.ReadInt "$a0") in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("l" <-[uint64T] "$r0");;;
    do:  ("vBytes" <-[sliceT] "$r1");;;
    return: (let: "l" := (![uint64T] "l") in
     let: "v" := (string.from_bytes (![sliceT] "vBytes")) in
     struct.make cacheValue [{
       "v" ::= "v";
       "l" ::= "l"
     }])).

(* go: clerk.go:55:19 *)
Definition CacheKv__Get : val :=
  rec: "CacheKv__Get" "k" "key" :=
    exception_do (let: "k" := (ref_ty ptrT "k") in
    let: "key" := (ref_ty stringT "key") in
    do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref CacheKv "mu" (![ptrT] "k")))) #());;;
    let: "ok" := (ref_ty boolT (zero_val boolT)) in
    let: "cv" := (ref_ty cacheValue (zero_val cacheValue)) in
    let: ("$ret0", "$ret1") := (map.get (![mapT stringT cacheValue] (struct.field_ref CacheKv "cache" (![ptrT] "k"))) (![stringT] "key")) in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("cv" <-[cacheValue] "$r0");;;
    do:  ("ok" <-[boolT] "$r1");;;
    let: "high" := (ref_ty uint64T (zero_val uint64T)) in
    let: ("$ret0", "$ret1") := (grove_ffi.GetTimeRange #()) in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  "$r0";;;
    do:  ("high" <-[uint64T] "$r1");;;
    (if: (![boolT] "ok") && ((![uint64T] "high") < (![uint64T] (struct.field_ref cacheValue "l" "cv")))
    then
      do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref CacheKv "mu" (![ptrT] "k")))) #());;;
      return: (![stringT] (struct.field_ref cacheValue "v" "cv"))
    else do:  #());;;
    do:  (let: "$a0" := (![mapT stringT cacheValue] (struct.field_ref CacheKv "cache" (![ptrT] "k"))) in
    let: "$a1" := (![stringT] "key") in
    map.delete "$a0" "$a1");;;
    do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref CacheKv "mu" (![ptrT] "k")))) #());;;
    return: (struct.field_get cacheValue "v" (let: "$a0" := (let: "$a0" := (![stringT] "key") in
     (interface.get "Get" (![kv.KvCput] (struct.field_ref CacheKv "kv" (![ptrT] "k")))) "$a0") in
     DecodeValue "$a0"))).

(* go: clerk.go:33:6 *)
Definition EncodeValue : val :=
  rec: "EncodeValue" "c" :=
    exception_do (let: "c" := (ref_ty cacheValue "c") in
    let: "e" := (ref_ty sliceT (zero_val sliceT)) in
    let: "$r0" := (slice.make2 byteT #(W64 0)) in
    do:  ("e" <-[sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![sliceT] "e") in
    let: "$a1" := (![uint64T] (struct.field_ref cacheValue "l" "c")) in
    marshal.WriteInt "$a0" "$a1") in
    do:  ("e" <-[sliceT] "$r0");;;
    let: "$r0" := (let: "$a0" := (![sliceT] "e") in
    let: "$a1" := (string.to_bytes (![stringT] (struct.field_ref cacheValue "v" "c"))) in
    marshal.WriteBytes "$a0" "$a1") in
    do:  ("e" <-[sliceT] "$r0");;;
    return: (string.from_bytes (![sliceT] "e"))).

(* go: clerk.go:40:6 *)
Definition max : val :=
  rec: "max" "a" "b" :=
    exception_do (let: "b" := (ref_ty uint64T "b") in
    let: "a" := (ref_ty uint64T "a") in
    (if: (![uint64T] "a") > (![uint64T] "b")
    then return: (![uint64T] "a")
    else do:  #());;;
    return: (![uint64T] "b")).

(* go: clerk.go:69:19 *)
Definition CacheKv__GetAndCache : val :=
  rec: "CacheKv__GetAndCache" "k" "key" "cachetime" :=
    exception_do (let: "k" := (ref_ty ptrT "k") in
    let: "cachetime" := (ref_ty uint64T "cachetime") in
    let: "key" := (ref_ty stringT "key") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (ref_ty stringT (zero_val stringT)) in
      let: "$r0" := (let: "$a0" := (![stringT] "key") in
      (interface.get "Get" (![kv.KvCput] (struct.field_ref CacheKv "kv" (![ptrT] "k")))) "$a0") in
      do:  ("enc" <-[stringT] "$r0");;;
      let: "old" := (ref_ty cacheValue (zero_val cacheValue)) in
      let: "$r0" := (let: "$a0" := (![stringT] "enc") in
      DecodeValue "$a0") in
      do:  ("old" <-[cacheValue] "$r0");;;
      let: "latest" := (ref_ty uint64T (zero_val uint64T)) in
      let: ("$ret0", "$ret1") := (grove_ffi.GetTimeRange #()) in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  "$r0";;;
      do:  ("latest" <-[uint64T] "$r1");;;
      let: "newLeaseExpiration" := (ref_ty uint64T (zero_val uint64T)) in
      let: "$r0" := (let: "$a0" := ((![uint64T] "latest") + (![uint64T] "cachetime")) in
      let: "$a1" := (![uint64T] (struct.field_ref cacheValue "l" "old")) in
      max "$a0" "$a1") in
      do:  ("newLeaseExpiration" <-[uint64T] "$r0");;;
      let: "resp" := (ref_ty stringT (zero_val stringT)) in
      let: "$r0" := (let: "$a0" := (![stringT] "key") in
      let: "$a1" := (![stringT] "enc") in
      let: "$a2" := (let: "$a0" := (let: "v" := (![stringT] (struct.field_ref cacheValue "v" "old")) in
      let: "l" := (![uint64T] "newLeaseExpiration") in
      struct.make cacheValue [{
        "v" ::= "v";
        "l" ::= "l"
      }]) in
      EncodeValue "$a0") in
      (interface.get "ConditionalPut" (![kv.KvCput] (struct.field_ref CacheKv "kv" (![ptrT] "k")))) "$a0" "$a1" "$a2") in
      do:  ("resp" <-[stringT] "$r0");;;
      (if: (![stringT] "resp") = #"ok"
      then
        do:  ((sync.Mutex__Lock (![ptrT] (struct.field_ref CacheKv "mu" (![ptrT] "k")))) #());;;
        let: "$r0" := (let: "v" := (![stringT] (struct.field_ref cacheValue "v" "old")) in
        let: "l" := (![uint64T] "newLeaseExpiration") in
        struct.make cacheValue [{
          "v" ::= "v";
          "l" ::= "l"
        }]) in
        do:  (map.insert (![mapT stringT cacheValue] (struct.field_ref CacheKv "cache" (![ptrT] "k"))) (![stringT] "key") "$r0");;;
        break: #()
      else do:  #()));;;
    let: "ret" := (ref_ty stringT (zero_val stringT)) in
    let: "$r0" := (struct.field_get cacheValue "v" (Fst (map.get (![mapT stringT cacheValue] (struct.field_ref CacheKv "cache" (![ptrT] "k"))) (![stringT] "key")))) in
    do:  ("ret" <-[stringT] "$r0");;;
    do:  ((sync.Mutex__Unlock (![ptrT] (struct.field_ref CacheKv "mu" (![ptrT] "k")))) #());;;
    return: (![stringT] "ret")).

(* go: clerk.go:90:19 *)
Definition CacheKv__Put : val :=
  rec: "CacheKv__Put" "k" "key" "val" :=
    exception_do (let: "k" := (ref_ty ptrT "k") in
    let: "val" := (ref_ty stringT "val") in
    let: "key" := (ref_ty stringT "key") in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (ref_ty stringT (zero_val stringT)) in
      let: "$r0" := (let: "$a0" := (![stringT] "key") in
      (interface.get "Get" (![kv.KvCput] (struct.field_ref CacheKv "kv" (![ptrT] "k")))) "$a0") in
      do:  ("enc" <-[stringT] "$r0");;;
      let: "leaseExpiration" := (ref_ty uint64T (zero_val uint64T)) in
      let: "$r0" := (struct.field_get cacheValue "l" (let: "$a0" := (![stringT] "enc") in
      DecodeValue "$a0")) in
      do:  ("leaseExpiration" <-[uint64T] "$r0");;;
      let: "earliest" := (ref_ty uint64T (zero_val uint64T)) in
      let: ("$ret0", "$ret1") := (grove_ffi.GetTimeRange #()) in
      let: "$r0" := "$ret0" in
      let: "$r1" := "$ret1" in
      do:  ("earliest" <-[uint64T] "$r0");;;
      do:  "$r1";;;
      (if: (![uint64T] "leaseExpiration") > (![uint64T] "earliest")
      then continue: #()
      else do:  #());;;
      let: "resp" := (ref_ty stringT (zero_val stringT)) in
      let: "$r0" := (let: "$a0" := (![stringT] "key") in
      let: "$a1" := (![stringT] "enc") in
      let: "$a2" := (let: "$a0" := (let: "v" := (![stringT] "val") in
      let: "l" := #(W64 0) in
      struct.make cacheValue [{
        "v" ::= "v";
        "l" ::= "l"
      }]) in
      EncodeValue "$a0") in
      (interface.get "ConditionalPut" (![kv.KvCput] (struct.field_ref CacheKv "kv" (![ptrT] "k")))) "$a0" "$a1" "$a2") in
      do:  ("resp" <-[stringT] "$r0");;;
      (if: (![stringT] "resp") = #"ok"
      then break: #()
      else do:  #()))).

Definition CacheKv__mset_ptr : list (string * val) := [
  ("Get", CacheKv__Get%V);
  ("GetAndCache", CacheKv__GetAndCache%V);
  ("Put", CacheKv__Put%V)
].

(* go: clerk.go:47:6 *)
Definition Make : val :=
  rec: "Make" "kv" :=
    exception_do (let: "kv" := (ref_ty kv.KvCput "kv") in
    return: (ref_ty CacheKv (let: "kv" := (![kv.KvCput] "kv") in
     let: "mu" := (ref_ty sync.Mutex (zero_val sync.Mutex)) in
     let: "cache" := (map.make stringT cacheValue #()) in
     struct.make CacheKv [{
       "kv" ::= "kv";
       "mu" ::= "mu";
       "cache" ::= "cache"
     }]))).
