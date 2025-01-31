(* autogenerated from github.com/mit-pdos/tulip/txnlog *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.tulip.tulip.

Section code.
Context `{ext_ty: ext_types}.

Definition Cmd := struct.decl [
  "Kind" :: uint64T;
  "Timestamp" :: uint64T;
  "PartialWrites" :: slice.T (struct.t tulip.WriteEntry)
].

Definition TxnLog := struct.decl [
].

(* Arguments:
   @ts: Transaction timestamp.

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
Definition TxnLog__SubmitCommit: val :=
  rec: "TxnLog__SubmitCommit" "log" "ts" "pwrs" :=
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

End code.
