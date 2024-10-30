(* autogenerated by goose record generator; do not modify *)
From New.code Require Import go_etcd_io.raft.v3.tracker.
From New.golang Require Import theory.

Axiom falso : False.

Module inflight.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  index : w64;
  bytes : w64;
}.
End def.
End inflight.

Global Instance into_val_inflight `{ffi_syntax} : IntoVal inflight.t.
Admitted.

Global Instance into_val_typed_inflight `{ffi_syntax} : IntoValTyped inflight.t inflight :=
{|
  default_val := inflight.mk (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_inflight_index `{ffi_syntax} : IntoValStructField "index" inflight inflight.index.
Admitted.

Global Instance into_val_struct_field_inflight_bytes `{ffi_syntax} : IntoValStructField "bytes" inflight inflight.bytes.
Admitted.

Instance wp_struct_make_inflight `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} index bytes:
  PureWp True
    (struct.make inflight (struct.fields_val [
      "index" ::= #index;
      "bytes" ::= #bytes
    ]))%V 
    #(inflight.mk index bytes).
Admitted.

Module Inflights.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  start : w64;
  count : w64;
  bytes : w64;
  size : w64;
  maxBytes : w64;
  buffer : slice.t;
}.
End def.
End Inflights.

Global Instance into_val_Inflights `{ffi_syntax} : IntoVal Inflights.t.
Admitted.

Global Instance into_val_typed_Inflights `{ffi_syntax} : IntoValTyped Inflights.t Inflights :=
{|
  default_val := Inflights.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_Inflights_start `{ffi_syntax} : IntoValStructField "start" Inflights Inflights.start.
Admitted.

Global Instance into_val_struct_field_Inflights_count `{ffi_syntax} : IntoValStructField "count" Inflights Inflights.count.
Admitted.

Global Instance into_val_struct_field_Inflights_bytes `{ffi_syntax} : IntoValStructField "bytes" Inflights Inflights.bytes.
Admitted.

Global Instance into_val_struct_field_Inflights_size `{ffi_syntax} : IntoValStructField "size" Inflights Inflights.size.
Admitted.

Global Instance into_val_struct_field_Inflights_maxBytes `{ffi_syntax} : IntoValStructField "maxBytes" Inflights Inflights.maxBytes.
Admitted.

Global Instance into_val_struct_field_Inflights_buffer `{ffi_syntax} : IntoValStructField "buffer" Inflights Inflights.buffer.
Admitted.

Instance wp_struct_make_Inflights `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} start count bytes size maxBytes buffer:
  PureWp True
    (struct.make Inflights (struct.fields_val [
      "start" ::= #start;
      "count" ::= #count;
      "bytes" ::= #bytes;
      "size" ::= #size;
      "maxBytes" ::= #maxBytes;
      "buffer" ::= #buffer
    ]))%V 
    #(Inflights.mk start count bytes size maxBytes buffer).
Admitted.

Module Progress.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Match : w64;
  Next : w64;
  sentCommit : w64;
  State : w64;
  PendingSnapshot : w64;
  RecentActive : bool;
  MsgAppFlowPaused : bool;
  Inflights : loc;
  IsLearner : bool;
}.
End def.
End Progress.

Global Instance into_val_Progress `{ffi_syntax} : IntoVal Progress.t.
Admitted.

Global Instance into_val_typed_Progress `{ffi_syntax} : IntoValTyped Progress.t Progress :=
{|
  default_val := Progress.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_Progress_Match `{ffi_syntax} : IntoValStructField "Match" Progress Progress.Match.
Admitted.

Global Instance into_val_struct_field_Progress_Next `{ffi_syntax} : IntoValStructField "Next" Progress Progress.Next.
Admitted.

Global Instance into_val_struct_field_Progress_sentCommit `{ffi_syntax} : IntoValStructField "sentCommit" Progress Progress.sentCommit.
Admitted.

Global Instance into_val_struct_field_Progress_State `{ffi_syntax} : IntoValStructField "State" Progress Progress.State.
Admitted.

Global Instance into_val_struct_field_Progress_PendingSnapshot `{ffi_syntax} : IntoValStructField "PendingSnapshot" Progress Progress.PendingSnapshot.
Admitted.

Global Instance into_val_struct_field_Progress_RecentActive `{ffi_syntax} : IntoValStructField "RecentActive" Progress Progress.RecentActive.
Admitted.

Global Instance into_val_struct_field_Progress_MsgAppFlowPaused `{ffi_syntax} : IntoValStructField "MsgAppFlowPaused" Progress Progress.MsgAppFlowPaused.
Admitted.

Global Instance into_val_struct_field_Progress_Inflights `{ffi_syntax} : IntoValStructField "Inflights" Progress Progress.Inflights.
Admitted.

Global Instance into_val_struct_field_Progress_IsLearner `{ffi_syntax} : IntoValStructField "IsLearner" Progress Progress.IsLearner.
Admitted.

Instance wp_struct_make_Progress `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Match Next sentCommit State PendingSnapshot RecentActive MsgAppFlowPaused Inflights IsLearner:
  PureWp True
    (struct.make Progress (struct.fields_val [
      "Match" ::= #Match;
      "Next" ::= #Next;
      "sentCommit" ::= #sentCommit;
      "State" ::= #State;
      "PendingSnapshot" ::= #PendingSnapshot;
      "RecentActive" ::= #RecentActive;
      "MsgAppFlowPaused" ::= #MsgAppFlowPaused;
      "Inflights" ::= #Inflights;
      "IsLearner" ::= #IsLearner
    ]))%V 
    #(Progress.mk Match Next sentCommit State PendingSnapshot RecentActive MsgAppFlowPaused Inflights IsLearner).
Admitted.

Module Config.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Voters : (vec loc 2);
  AutoLeave : bool;
  Learners : loc;
  LearnersNext : loc;
}.
End def.
End Config.

Global Instance into_val_Config `{ffi_syntax} : IntoVal Config.t.
Admitted.

Global Instance into_val_typed_Config `{ffi_syntax} : IntoValTyped Config.t Config :=
{|
  default_val := Config.mk (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_Config_Voters `{ffi_syntax} : IntoValStructField "Voters" Config Config.Voters.
Admitted.

Global Instance into_val_struct_field_Config_AutoLeave `{ffi_syntax} : IntoValStructField "AutoLeave" Config Config.AutoLeave.
Admitted.

Global Instance into_val_struct_field_Config_Learners `{ffi_syntax} : IntoValStructField "Learners" Config Config.Learners.
Admitted.

Global Instance into_val_struct_field_Config_LearnersNext `{ffi_syntax} : IntoValStructField "LearnersNext" Config Config.LearnersNext.
Admitted.

Instance wp_struct_make_Config `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Voters AutoLeave Learners LearnersNext:
  PureWp True
    (struct.make Config (struct.fields_val [
      "Voters" ::= #Voters;
      "AutoLeave" ::= #AutoLeave;
      "Learners" ::= #Learners;
      "LearnersNext" ::= #LearnersNext
    ]))%V 
    #(Config.mk Voters AutoLeave Learners LearnersNext).
Admitted.

Module ProgressTracker.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  Config : Config.t;
  Progress : loc;
  Votes : loc;
  MaxInflight : w64;
  MaxInflightBytes : w64;
}.
End def.
End ProgressTracker.

Global Instance into_val_ProgressTracker `{ffi_syntax} : IntoVal ProgressTracker.t.
Admitted.

Global Instance into_val_typed_ProgressTracker `{ffi_syntax} : IntoValTyped ProgressTracker.t ProgressTracker :=
{|
  default_val := ProgressTracker.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_ProgressTracker_Config `{ffi_syntax} : IntoValStructField "Config" ProgressTracker ProgressTracker.Config.
Admitted.

Global Instance into_val_struct_field_ProgressTracker_Progress `{ffi_syntax} : IntoValStructField "Progress" ProgressTracker ProgressTracker.Progress.
Admitted.

Global Instance into_val_struct_field_ProgressTracker_Votes `{ffi_syntax} : IntoValStructField "Votes" ProgressTracker ProgressTracker.Votes.
Admitted.

Global Instance into_val_struct_field_ProgressTracker_MaxInflight `{ffi_syntax} : IntoValStructField "MaxInflight" ProgressTracker ProgressTracker.MaxInflight.
Admitted.

Global Instance into_val_struct_field_ProgressTracker_MaxInflightBytes `{ffi_syntax} : IntoValStructField "MaxInflightBytes" ProgressTracker ProgressTracker.MaxInflightBytes.
Admitted.

Instance wp_struct_make_ProgressTracker `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} Config Progress Votes MaxInflight MaxInflightBytes:
  PureWp True
    (struct.make ProgressTracker (struct.fields_val [
      "Config" ::= #Config;
      "Progress" ::= #Progress;
      "Votes" ::= #Votes;
      "MaxInflight" ::= #MaxInflight;
      "MaxInflightBytes" ::= #MaxInflightBytes
    ]))%V 
    #(ProgressTracker.mk Config Progress Votes MaxInflight MaxInflightBytes).
Admitted.
