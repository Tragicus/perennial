(* autogenerated from github.com/goose-lang/goose/internal/examples/trust_import/trusted_example *)
From Perennial.goose_lang Require Import prelude.

Section code.
Context `{ext_ty: ext_types}.
Local Coercion Var' s: expr := Var s.

Definition Foo: val :=
  rec: "Foo" <> :=
    (* fmt.Println("Blah") *)
    #().

End code.