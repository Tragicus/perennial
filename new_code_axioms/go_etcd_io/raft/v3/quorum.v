(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom JointConfig : go_type.
Axiom JointConfig__mset : list (string * val).
Axiom JointConfig__mset_ptr : list (string * val).
Axiom JointConfig__String : val.
Axiom JointConfig__IDs : val.
Axiom JointConfig__Describe : val.
Axiom JointConfig__CommittedIndex : val.
Axiom JointConfig__VoteResult : val.
Axiom MajorityConfig : go_type.
Axiom MajorityConfig__mset : list (string * val).
Axiom MajorityConfig__mset_ptr : list (string * val).
Axiom MajorityConfig__String : val.
Axiom MajorityConfig__Describe : val.
Axiom MajorityConfig__Slice : val.
Axiom MajorityConfig__CommittedIndex : val.
Axiom MajorityConfig__VoteResult : val.
Axiom Index : go_type.
Axiom Index__mset : list (string * val).
Axiom Index__mset_ptr : list (string * val).
Axiom Index__String : val.
Axiom AckedIndexer : go_type.
Axiom AckedIndexer__mset : list (string * val).
Axiom AckedIndexer__mset_ptr : list (string * val).
Axiom mapAckIndexer__AckedIndex : val.
Axiom VoteResult : go_type.
Axiom VoteResult__mset : list (string * val).
Axiom VoteResult__mset_ptr : list (string * val).
Axiom VotePending : val.
Axiom VoteLost : val.
Axiom VoteWon : val.
Axiom VoteResult__String : val.

End axioms.
