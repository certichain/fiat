Section BookStoreExamples.
  Require Import QueryStructureNotations.
  Require Import ListImplementation.

  (* Our bookstore has two relations (tables):
     - The [Books] relation contains the books in the
       inventory, represented as a tuple with
       [Author], [Title], and [ISBN] attributes.
       The [ISBN] attribute is a key for the relation,
       specified by the [where attributes .. depend on ..]
       constraint.
     - The [Orders] relation contains the orders that
       have been placed, represented as a tuple with the
       [ISBN] and [Date] attributes.

     The schema for the entire query structure specifies that
     the [ISBN] attribute of [Orders] is a foreign key into
     [Books], specified by the [attribute .. of .. references ..]
     constraint.
   *)

  Check (schema <"Author" :: string,
         "Title" :: string,
         "ISBN" :: nat>
         where attributes ["Title"; "Author"] depend on ["ISBN"]).

  Definition BookStoreSchema :=
    Query Structure Schema
      [ relation "Books" has
                schema <"Author" :: string,
                        "Title" :: string,
                        "ISBN" :: nat>
                        where attributes ["Title"; "Author"] depend on ["ISBN"];
        relation "Orders" has
                schema <"ISBN" :: nat,
                        "Date" :: nat> ]
      enforcing [attribute "ISBN" of "Orders" references "Books"].

  (* Aliases for the tuples contained in Books and Orders, respectively. *)
  Definition Book := TupleDef BookStoreSchema "Books".
  Definition Order := TupleDef BookStoreSchema "Orders".

  (* Our bookstore has two mutators:
     - [PlaceOrder] : Place an order into the 'Orders' table
     - [AddBook] : Add a book to the inventory

     Our bookstore has two observers:
     - [GetTitles] : The titles of books written by a given author
     - [NumOrders] : The number of orders for a given author
   *)

  Definition BookStoreSig : ADTSig :=
    ADTsignature {
        "InitBookstore" : unit → rep,
        "PlaceOrder" : rep × Order → rep × unit,
        "AddBook" : rep × Book → rep × unit,
        "GetTitles" : rep × string → rep × list string,
        "NumOrders" : rep × string → rep × nat
      }.

  Definition BookStoreSpec : ADT BookStoreSig :=
    QueryADTRep BookStoreSchema {
      const "InitBookstore" (_ : unit) : rep := empty,

      update "PlaceOrder" ( o : Order ) : unit :=
          Insert o into "Orders",

      update "AddBook" ( b : Book ) : unit :=
          Insert b into "Books" ,

      query "GetTitles" ( author : string ) : list string :=
        For (b in "Books")
        Where (author = b!"Author")
        Return (b!"Title"),

       query "NumOrders" ( author : string ) : nat :=
          Count (For (o in "Orders") (b in "Books")
                 Where (author = b!"Author")
                 Where (b!"ISBN" = o!"ISBN")
                 Return o!"ISBN")
  }.

  Require Import BagsOfTuples.

  Definition BookStoreListImpl_AbsR
             (or : UnConstrQueryStructure BookStoreSchema)
             (nr : list Book * list Order) : Prop :=
    or ! "Books" ≃ benumerate (fst nr) /\ or ! "Orders" ≃ benumerate (snd nr).

  Opaque Query_For.

  Definition BookStore :
    Sharpened BookStoreSpec.
  Proof.
    unfold BookStoreSpec.

    (* Step 1: Drop the constraints on the tables. From the perspective
      of a client of a sharpened ADT the invariants will still hold,
      since ADT refinement preserves the simulation relation. *)

    start honing QueryStructure.

    hone representation using BookStoreListImpl_AbsR.

    hone method "PlaceOrder".
    {
      setoid_rewrite refineEquiv_pick_ex_computes_to_bind_and.
      rewrite refine_pick_val with (A := nat) (a := length (snd r_n)).
      simplify with monad laws.
      setoid_rewrite refineEquiv_split_ex.
      setoid_rewrite refineEquiv_pick_computes_to_and.
      simplify with monad laws.
      (* TODO: remove this etransitivity, apply step. *)
      etransitivity.
      apply refine_bind.
      eapply (@refine_foreign_key_check
                 _
                 _ (fst r_n)
      (fun tup2 : Tuple => n ``("ISBN") = tup2 ``("ISBN"))).
      destruct H; eauto.
      unfold pointwise_relation; intros; higher_order_1_reflexivity.
      (* END TODO*)
      simplify with monad laws.
      unfold If_Then_Else; rewrite refine_if_bool_eta.
      simplify with monad laws.
      rewrite refine_pick_eq_ex_bind; unfold BookStoreListImpl_AbsR in *.
      split_and; simpl;
      rewrite refineEquiv_pick_pair_pair;
      setoid_rewrite refineEquiv_pick_eq';
      simplify with monad laws; simpl.
      Split Constraint Checks.
      (* TODO move this back to a tactic *)
      etransitivity.
      apply refine_bind.
      match goal with
          |- context
               [{a | EnsembleIndexedListEquivalence
                       ((@UpdateUnConstrRelation ?QSSchema ?c ?Ridx
                                                (EnsembleInsert ?n (?c!?R)))!?R')%QueryImpl a}%comp] =>
          let H := fresh in
          generalize ((@ImplementListInsert_neq QSSchema
                                                {| bindex := R' |}
                                                {| bindex := R |} n c)) as H; intros; setoid_rewrite H
      end; try reflexivity; try eassumption.
      congruence.
      unfold pointwise_relation; intros.
      setoid_rewrite (@ImplementListInsert_eq); eauto.
      simplify with monad laws.
      higher_order_1_reflexivity.
      simplify with monad laws.
      reflexivity.
      rewrite refine_pick_val; eauto.
      simplify with monad laws.
      rewrite refine_pick_val; eauto.
      simplify with monad laws.
      reflexivity.
      intros.
      destruct H as [_ [l l']].
      generalize (l _ H1).
      unfold not; intros.
      eapply lt_irrefl.
      destruct tup; simpl in *; subst.
      eapply H.
    }

    hone method "AddBook".
    {
      setoid_rewrite refineEquiv_pick_ex_computes_to_bind_and.
      rewrite refine_pick_val with (A := nat) (a := length (fst r_n)).
      simplify with monad laws.
      setoid_rewrite refineEquiv_split_ex.
      setoid_rewrite refineEquiv_pick_computes_to_and.
      simplify with monad laws.
      rewrite refine_tupleAgree_refl_True;
        simplify with monad laws.
      (* Again, to tactics *)
      repeat match goal with
          |- context [
                 forall tup' : @IndexedTuple ?h,
                   (?qs ! ?R )%QueryImpl tup' ->
                   tupleAgree ?n (indexedTuple tup') ?attrlist2%SchemaConstraints ->
                   tupleAgree ?n (indexedTuple tup') ?attrlist1%SchemaConstraints ]
              =>
              let H' := fresh in
              generalize (@refine_unused_key_check h attrlist1 attrlist2 _ _ n (qs ! R )%QueryImpl) as H'; intros; setoid_rewrite H'; clear H';
              [ simplify with monad laws |
                unfold BookStoreListImpl_AbsR in *; split_and; eauto ]
        | |- context [
                 forall tup' : @IndexedTuple ?h,
                   (?qs ! ?R )%QueryImpl tup' ->
                   tupleAgree (indexedTuple tup') ?n ?attrlist2%SchemaConstraints ->
                   tupleAgree (indexedTuple tup') ?n  ?attrlist1%SchemaConstraints]
                =>
                let H' := fresh in
                generalize (@refine_unused_key_check' h attrlist1 attrlist2 _ _ n (qs ! R )%QueryImpl) as H'; intros; setoid_rewrite H'; clear H';
                  [ simplify with monad laws |
                    unfold BookStoreListImpl_AbsR in *; split_and; eauto ]
      end.
      rewrite refine_pick_eq_ex_bind; unfold BookStoreListImpl_AbsR in *.
      split_and; simpl;
      rewrite refineEquiv_pick_pair_pair;
      setoid_rewrite refineEquiv_pick_eq';
      simplify with monad laws; simpl.
      Split Constraint Checks.
      (* TODO move this back to a tactic *)
      setoid_rewrite (@ImplementListInsert_eq); eauto.
      simplify with monad laws.
      match goal with
          |- context
               [{a | EnsembleIndexedListEquivalence
                       ((@UpdateUnConstrRelation ?QSSchema ?c ?Ridx
                                                (EnsembleInsert ?n (?c!?R)))!?R')%QueryImpl a}%comp] =>
          let H := fresh in
          generalize ((@ImplementListInsert_neq QSSchema
                                                {| bindex := R' |}
                                                {| bindex := R |} n c)) as H; intros; setoid_rewrite H
      end; try reflexivity; try eassumption.
      congruence.
      rewrite refine_pick_val; eauto;
      simplify with monad laws.
      rewrite refine_pick_val; eauto;
      simplify with monad laws.
      reflexivity.
      rewrite refine_pick_val; eauto;
      simplify with monad laws.
      rewrite refine_pick_val; eauto;
      simplify with monad laws.
      reflexivity.
      intros.
      destruct H as [[l l'] _].
      generalize (l _ H1).
      unfold not; intros.
      eapply lt_irrefl.
      destruct tup; simpl in *; subst.
      eapply H.
    }

    hone method "GetTitles".
    {
      simpl.
      unfold BookStoreListImpl_AbsR in H; split_and.
      setoid_rewrite refineEquiv_pick_ex_computes_to_and.
      simplify with monad laws.
      rewrite refine_List_Query_In; eauto.
      rewrite refine_List_Query_In_Where.
      rewrite refine_List_For_Query_In_Return;
        simplify with monad laws; simpl.

      setoid_rewrite refineEquiv_pick_pair_pair.
      setoid_rewrite refineEquiv_pick_eq'.
      simplify with monad laws.
      rewrite refine_pick_val by eassumption.
      simplify with monad laws.
      rewrite refine_pick_val by eassumption.
      simplify with monad laws.
      finish honing.
  }

    hone method "NumOrders".
    {
      simpl.
      unfold BookStoreListImpl_AbsR in H; split_and.
      setoid_rewrite refineEquiv_pick_ex_computes_to_and.
      simplify with monad laws.
      rewrite refine_List_Query_In; eauto.
      rewrite refine_Join_List_Query_In; eauto.
      rewrite refine_List_Query_In_Where.
      rewrite refine_List_Query_In_Where.
      rewrite refine_List_For_Query_In_Return;
        simplify with monad laws; simpl.

      setoid_rewrite refineEquiv_pick_pair_pair.
      setoid_rewrite refineEquiv_pick_eq'.
      simplify with monad laws.
      rewrite refine_pick_val by eassumption.
      simplify with monad laws.
      rewrite refine_pick_val by eassumption.
      simplify with monad laws.
      finish honing.
  }

    implement_empty_list "InitBookstore" BookStoreListImpl_AbsR.

    (* Step 4: Profit. :) *)

    finish sharpening.
  Defined.
End BookStoreExamples.
