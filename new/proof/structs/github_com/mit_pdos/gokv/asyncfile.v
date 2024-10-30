(* autogenerated by goose record generator; do not modify *)
From New.code Require Import github_com.mit_pdos.gokv.asyncfile.
From New.golang Require Import theory.

Axiom falso : False.

Module AsyncFile.
Section def.
Context `{ffi_syntax}.
Record t := mk {
  mu : loc;
  data : slice.t;
  filename : string;
  index : w64;
  indexCond : loc;
  durableIndex : w64;
  durableIndexCond : loc;
  closeRequested : bool;
  closed : bool;
  closedCond : loc;
}.
End def.
End AsyncFile.

Global Instance into_val_AsyncFile `{ffi_syntax} : IntoVal AsyncFile.t.
Admitted.

Global Instance into_val_typed_AsyncFile `{ffi_syntax} : IntoValTyped AsyncFile.t AsyncFile :=
{|
  default_val := AsyncFile.mk (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _) (default_val _);
  to_val_has_go_type := ltac:(destruct falso);
  default_val_eq_zero_val := ltac:(destruct falso);
  to_val_inj := ltac:(destruct falso);
  to_val_eqdec := ltac:(solve_decision);
|}.
Global Instance into_val_struct_field_AsyncFile_mu `{ffi_syntax} : IntoValStructField "mu" AsyncFile AsyncFile.mu.
Admitted.

Global Instance into_val_struct_field_AsyncFile_data `{ffi_syntax} : IntoValStructField "data" AsyncFile AsyncFile.data.
Admitted.

Global Instance into_val_struct_field_AsyncFile_filename `{ffi_syntax} : IntoValStructField "filename" AsyncFile AsyncFile.filename.
Admitted.

Global Instance into_val_struct_field_AsyncFile_index `{ffi_syntax} : IntoValStructField "index" AsyncFile AsyncFile.index.
Admitted.

Global Instance into_val_struct_field_AsyncFile_indexCond `{ffi_syntax} : IntoValStructField "indexCond" AsyncFile AsyncFile.indexCond.
Admitted.

Global Instance into_val_struct_field_AsyncFile_durableIndex `{ffi_syntax} : IntoValStructField "durableIndex" AsyncFile AsyncFile.durableIndex.
Admitted.

Global Instance into_val_struct_field_AsyncFile_durableIndexCond `{ffi_syntax} : IntoValStructField "durableIndexCond" AsyncFile AsyncFile.durableIndexCond.
Admitted.

Global Instance into_val_struct_field_AsyncFile_closeRequested `{ffi_syntax} : IntoValStructField "closeRequested" AsyncFile AsyncFile.closeRequested.
Admitted.

Global Instance into_val_struct_field_AsyncFile_closed `{ffi_syntax} : IntoValStructField "closed" AsyncFile AsyncFile.closed.
Admitted.

Global Instance into_val_struct_field_AsyncFile_closedCond `{ffi_syntax} : IntoValStructField "closedCond" AsyncFile AsyncFile.closedCond.
Admitted.

Instance wp_struct_make_AsyncFile `{ffi_semantics} `{!ffi_interp ffi} `{!heapGS Σ} mu data filename index indexCond durableIndex durableIndexCond closeRequested closed closedCond:
  PureWp True
    (struct.make AsyncFile (struct.fields_val [
      "mu" ::= #mu;
      "data" ::= #data;
      "filename" ::= #filename;
      "index" ::= #index;
      "indexCond" ::= #indexCond;
      "durableIndex" ::= #durableIndex;
      "durableIndexCond" ::= #durableIndexCond;
      "closeRequested" ::= #closeRequested;
      "closed" ::= #closed;
      "closedCond" ::= #closedCond
    ]))%V 
    #(AsyncFile.mk mu data filename index indexCond durableIndex durableIndexCond closeRequested closed closedCond).
Admitted.

