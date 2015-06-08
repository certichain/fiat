(** Sharpened ADT for an expression grammar with + and () *)
Require Import Coq.Init.Wf Coq.Arith.Wf_nat.
Require Import Coq.Lists.List.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Fiat.Parsers.Refinement.Tactics.
Require Import Fiat.Parsers.Grammars.ExpressionNumPlusParen.
Require Import Fiat.Computation.Refinements.General.
Require Import Fiat.Parsers.StringLike.Properties.
Require Import Fiat.Parsers.StringLike.String.
Require Import Fiat.Common.
Require Import Fiat.Common.Equality.
Require Import Fiat.Common.Wf.
Require Import Fiat.Parsers.Splitters.RDPList.
Require Import Fiat.Parsers.BaseTypes.
Require Import Fiat.Parsers.Refinement.FixedLengthLemmas.
Require Import Fiat.Parsers.Refinement.DisjointRules.
Require Import Fiat.Parsers.Refinement.BinOpBrackets.MakeBinOpTable.
Require Import Fiat.Parsers.Refinement.BinOpBrackets.BinOpRules.
Require Import Fiat.Parsers.ExtrOcamlParsers. (* for simpl rules for [find_first_char_such_that] *)

Set Implicit Arguments.

Section IndexedImpl.
  Typeclasses Opaque If_Then_Else.

  (** TODO: generate this automatically? *)
  Local Instance pbh_plus : paren_balanced_hiding_dataT Ascii.ascii
    := { is_bin_op := ascii_beq "+"%char;
         is_open := ascii_beq "("%char;
         is_close := ascii_beq ")"%char }.

  Lemma ComputationalSplitter'
  : FullySharpened (string_spec plus_expr_grammar).
  Proof.
    start honing parser using indexed representation.


    hone method "splits".
    {
      simplify parser splitter.
      setoid_rewrite refine_binop_table; [ | reflexivity.. ].
      simpl.
      finish honing parser method.
    }

    FullySharpenEachMethodWithoutDelegation.
    extract delegate-free implementation.
    simpl; higher_order_reflexivityT.
  Defined.

  Lemma ComputationalSplitter
  : FullySharpened (string_spec plus_expr_grammar).
  Proof.
    let impl := (eval simpl in (projT1 ComputationalSplitter')) in
    refine (existT _ impl _).
    abstract (exact (projT2 ComputationalSplitter')).
  Defined.

End IndexedImpl.

Global Arguments ComputationalSplitter / .

Require Import Fiat.Parsers.ParserFromParserADT.
Require Import Fiat.Parsers.ExtrOcamlParsers.
Import Fiat.Parsers.ExtrOcamlParsers.HideProofs.

Time Definition paren_expr_parser (str : String.string) : bool
  := Eval simpl in has_parse (parser ComputationalSplitter) str.

Print paren_expr_parser.

Recursive Extraction paren_expr_parser.
