Require Import String Omega List FunctionalExtensionality Ensembles
        Computation ADT ADTRefinement ADTNotation QueryStructureSchema
        QueryQSSpecs InsertQSSpecs QueryStructure.

Lemma tupleAgree_refl :
  forall (h : Heading)
         (tup : @Tuple h)
         (attrlist : list (Attributes h)),
    tupleAgree tup tup attrlist.
Proof.
  unfold tupleAgree; auto.
Qed.

Lemma refine_tupleAgree_refl_True :
  forall (h : Heading)
         (tup : @Tuple h)
         (attrlist attrlist' : list (Attributes h)),
    refine {b |
            decides b (tupleAgree tup tup attrlist'
                       -> tupleAgree tup tup attrlist)}
           (ret true).
Proof.
  unfold refine; intros; inversion_by computes_to_inv.
  subst; econstructor; simpl; auto using tupleAgree_refl.
Qed.

Ltac simplify_trivial_SatisfiesSchemaConstraints :=
  simpl;
  try rewrite refine_tupleAgree_refl_True;
  try setoid_rewrite decides_True;
  try setoid_rewrite decides_2_True; reflexivity.

Ltac simplify_trivial_SatisfiesCrossRelationConstraints :=
  simpl; try setoid_rewrite decides_True;
  try setoid_rewrite decides_3_True;
  repeat setoid_rewrite refineEquiv_bind_unit;
  unfold If_Then_Else;
  try setoid_rewrite refine_if_bool_eta; reflexivity.

Tactic Notation "remove" "trivial" "insertion" "checks" :=
  (* Move all the binds we can outside the exists / computes
   used for abstraction. *)
  repeat setoid_rewrite refineEquiv_pick_ex_computes_to_bind_and;
  (* apply etransitivity in order to rewrite insert first and
     then simplify the trivial constraints. *)
  etransitivity;
  [ (* drill under the binds so that we can rewrite [QSInsertSpec]
     (we can't use setoid_rewriting because there's a 'deep metavariable'
     *)
    repeat (apply refine_bind;
            [ reflexivity
            | unfold pointwise_relation; intros] );
    (* Pull out the relation we're inserting into and then
     rewrite [QSInsertSpec] *)
            match goal with
                |- context [(Insert _ into ?R)%QuerySpec] =>
                eapply (@QSInsertSpec_UnConstr_refine
                          _ _ R _)
            end;
            (* try to discharge the trivial constraints *)
            [  simplify_trivial_SatisfiesSchemaConstraints
             | simplify_trivial_SatisfiesSchemaConstraints
             | simplify_trivial_SatisfiesSchemaConstraints
             | simplify_trivial_SatisfiesCrossRelationConstraints
             | simplify_trivial_SatisfiesCrossRelationConstraints
             | eauto ]
  | (* simplify using the monad laws *)
  repeat setoid_rewrite refineEquiv_bind_unit;
    repeat setoid_rewrite refineEquiv_bind_bind;
    repeat setoid_rewrite refineEquiv_bind_unit;
    try rewrite <- GetRelDropConstraints;
    repeat match goal with
             | H : DropQSConstraints_SiR ?qs ?uqs |- _ =>
               rewrite H in *; clear qs H
           end
    ].

Tactic Notation "Split" "Constraint" "Checks" :=
  let b := match goal with
             | [ |- context[if ?X then _ else _] ] => constr:(X)
             | [ H : context[if ?X then _ else _] |- _ ]=> constr:(X)
           end in
  let b_eq := fresh in
  eapply (@refine_if _ _ b); intros b_eq;
  repeat setoid_rewrite b_eq;
  repeat rewrite b_eq.

Tactic Notation "implement" "failed" "insert" :=
  repeat (rewrite refine_pick_val, refineEquiv_bind_unit; eauto);
  reflexivity.