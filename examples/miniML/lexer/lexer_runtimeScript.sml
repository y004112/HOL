(* The runtime driver for the lexer that converts a string to a token list,
 * given a DFA *)
open preamble;
open stringTheory finite_mapTheory;
open lcsymtacs;
open dfaTheory lexer_specTheory;

val strcat_lem = Q.prove (
`!s1 s2 s3 s4.
  (STRLEN s1 = STRLEN s3) ∧ (STRCAT s1 s2 = STRCAT s3 s4)
  ⇒
  (s1 = s3) ∧
  (s2 = s4)`,
Induct_on `s1` >>
rw [] >>
Cases_on `s3` >>
fs [] >>
metis_tac []);

val _ = new_theory "lexer_runtime";

val min_lem = Q.prove (
`!P n. P (n:num) ⇒ ?n'. P n' ∧ (!n''. n'' < n' ⇒ ¬P n'')`,
completeInduct_on `n` >>
rw [] >>
metis_tac []);

val split_end = Q.prove (
`!s. (s ≠ []) ⇒ ?s' x. (s = s' ++ [x])`,
induct_on `s` >>
rw [] >>
cases_on `s = []` >>
fs []);

val REVERSE_11 = Q.prove (
`!x y. (REVERSE x = REVERSE y) = (x = y)`,
induct_on `x` >>
rw [] >>
cases_on `y` >>
fs [] >>
metis_tac []);

val exists_split = Q.prove (
`!P l.
  EXISTS P l
  ⇒
  ?l1 x l2. (l = l1 ++ [x] ++ l2) ∧ ~EXISTS P l1 ∧ P x`,
induct_on `l` >>
rw [] >|
[qexists_tac `[]` >>
     rw [],
 cases_on `P h` >|
     [qexists_tac `[]` >>
          rw [],
      res_tac >>
          rw [] >>
          fs [] >>
          qexists_tac `h::l1` >>
          rw []]]);

val lexer_get_token_def = Define `
(lexer_get_token transition finals cur_state cur_lexeme prev_answer [] =
   prev_answer) ∧
(lexer_get_token transition finals cur_state cur_lexeme prev_answer (c::s) =
   case FLOOKUP transition (cur_state,c) of
     | NONE => prev_answer
     | SOME next_state =>
         lexer_get_token transition finals next_state
           (c::cur_lexeme)
           (case FLOOKUP finals next_state of
              | NONE => prev_answer
              | SOME tok => SOME (tok, c::cur_lexeme, s))
           s)`;

val lexer_get_token_invariant_def = Define `
lexer_get_token_invariant transition finals start state lexeme answer s =
  case answer of
    | NONE =>
        ∃path.
          dfa_path transition start state path ∧
          (REVERSE lexeme = MAP FST path) ∧
          EVERY (\extra_state. FLOOKUP finals extra_state = NONE) (MAP SND path)
    | SOME (answer_tok, answer_lexeme, answer_rest) =>
        ∃intermediate_state answer_path path_extension.
          dfa_path transition start intermediate_state answer_path ∧
          dfa_path transition intermediate_state state path_extension ∧
          (REVERSE answer_lexeme = MAP FST answer_path) ∧
          (FLOOKUP finals intermediate_state = SOME answer_tok) ∧
          (REVERSE answer_lexeme ++ answer_rest = REVERSE lexeme ++ s) ∧
          (REVERSE lexeme = MAP FST (answer_path ++ path_extension)) ∧
          EVERY (\extra_state. FLOOKUP finals extra_state = NONE)
                (MAP SND path_extension)`;

val lexer_get_token_preserves_invariant = Q.prove (
`∀transition finals start state lexeme answer s c next_state.
  lexer_get_token_invariant transition finals start state lexeme answer (c::s) ∧
  (FLOOKUP transition (state,c) = SOME next_state)
  ⇒
  lexer_get_token_invariant transition finals start next_state (c::lexeme)
    (case FLOOKUP finals next_state of
       | NONE => answer
       | SOME tok => SOME (tok, c::lexeme, s))
    s`,
rw [lexer_get_token_invariant_def] >>
cases_on `FLOOKUP finals next_state` >>
rw [] >>
cases_on `answer` >>
fs [] >|
[qexists_tac `path++[(c,next_state)]` >>
     rw [] >>
     metis_tac [dfa_path_extend],
 PairCases_on `x` >>
     fs [] >>
     MAP_EVERY qexists_tac
               [`intermediate_state`, `answer_path`,
                `path_extension++[(c,next_state)]`] >>
     rw [] >>
     metis_tac [dfa_path_extend],
     MAP_EVERY qexists_tac
               [`next_state`, `path++[(c,next_state)]`, `[]`] >>
     rw [] >-
     metis_tac [dfa_path_extend] >>
     rw [dfa_path_def],
 PairCases_on `x'` >>
     fs [] >>
     MAP_EVERY qexists_tac
               [`next_state`, `answer_path++path_extension++[(c,next_state)]`,
                `[]`] >>
     rw [] >-
     metis_tac [dfa_path_extend,dfa_path_append]>>
     rw [dfa_path_def]]);

val lexer_get_token_invariant_initial = Q.prove (
`!transition finals start s.
  lexer_get_token_invariant transition finals start start "" NONE s`,
rw [lexer_get_token_invariant_def, dfa_path_def] >>
cases_on `FLOOKUP finals start` >>
rw []);

val lexer_get_token_partial_correctness_lem1 = Q.prove (
`!l1 l2 l3.
  (MAP FST l1 ++ l2 = MAP FST l3) ⇒
  ∃l4 l5. (l3 = l4 ++ l5) ∧ (l2 = MAP FST l5)`,
Induct_on `l3` >>
rw [] >>
cases_on `l1` >>
rw [] >>
fs [] >|
[qexists_tac `[]` >>
     rw [],
 res_tac >>
     rw [] >>
     qexists_tac `h::l4` >>
     rw []]);

val lexer_get_token_partial_correctness_lem2 = Q.prove (
`!path_extension' s'' path_extension h s state state' transition
      intermediate_state.
  (MAP FST path_extension' ++ s'' = MAP FST path_extension ++ [h] ++ s) ∧
  dfa_path transition intermediate_state state' path_extension' ∧
  dfa_path transition intermediate_state state path_extension ∧
  (FLOOKUP transition (state,h) = NONE)
  ⇒
  ?pe. path_extension = path_extension' ++ pe`,
induct_on `path_extension'` >>
rw [] >>
PairCases_on `h` >>
fs [dfa_path_def] >>
every_case_tac >>
fs [] >>
cases_on `path_extension` >>
fs [dfa_path_def] >>
rw [] >>
fs [] >>
PairCases_on `h` >>
fs [dfa_path_def] >>
metis_tac []);

val lexer_get_token_partial_correctness = Q.prove (
`∀transition finals start state lexeme answer s tok lexeme' s'.
  lexer_get_token_invariant transition finals start state lexeme answer s ∧
  (lexer_get_token transition finals state lexeme answer s =
   SOME (tok,lexeme',s'))
  ⇒
  ∃state path.
    dfa_path transition start state path ∧
    (REVERSE lexeme' = MAP FST path) ∧
    (FLOOKUP finals state = SOME tok) ∧
    (REVERSE lexeme' ++ s' = REVERSE lexeme ++ s) ∧
    (∀path_extension state'.
      dfa_path transition state state' path_extension ∧
      (?s''. MAP FST path_extension ++ s'' = s')
      ⇒
      EVERY (\extra_state. FLOOKUP finals extra_state = NONE)
            (MAP SND path_extension))`,
induct_on `s` >>
rw [lexer_get_token_def] >>
every_case_tac >>
fs [] >>
rw [] >|
[fs [lexer_get_token_invariant_def] >>
     `s' = MAP FST path_extension` by metis_tac [APPEND_11] >>
     rw [] >>
     MAP_EVERY qexists_tac [`intermediate_state`, `answer_path`] >>
     rw [] >>
     imp_res_tac lexer_get_token_partial_correctness_lem1 >>
     rw [] >>
     fs [dfa_path_append] >>
     `path_extension' = l4` by metis_tac [dfa_path_determ] >>
     rw [],
 fs [lexer_get_token_invariant_def] >>
     `s' = MAP FST path_extension ++ [h] ++ s`
                by metis_tac [APPEND_11, APPEND_ASSOC] >>
     rw [] >>
     MAP_EVERY qexists_tac [`intermediate_state`, `answer_path`] >>
     rw [] >>
     fs [] >>
     imp_res_tac lexer_get_token_partial_correctness_lem2 >>
     rw [] >>
     fs [dfa_path_append],
 imp_res_tac lexer_get_token_preserves_invariant >>
     every_case_tac >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     qexists_tac `state''` >>
     qexists_tac `path'` >>
     rw [] >>
     metis_tac [],
 imp_res_tac lexer_get_token_preserves_invariant >>
     every_case_tac >>
     fs [] >>
     rw [] >>
     res_tac >>
     fs [] >>
     qexists_tac `state''` >>
     qexists_tac `path'` >>
     rw [] >>
     metis_tac []]);

val lexer_get_token_no_more_final = Q.prove (
`∀trans start state path finals lexeme answer s c s'.
  dfa_path trans start state path ∧
  (FLOOKUP finals start = NONE) ∧
  EVERY (λextra_state. FLOOKUP finals extra_state = NONE) (MAP SND path) ∧
  ((s = []) ∨ ((s = c::s') ∧ (FLOOKUP trans (state,c) = NONE)))
  ⇒
  (lexer_get_token trans finals start lexeme answer (MAP FST path++s) =
   answer)`,
recInduct dfa_path_ind >>
rw [lexer_get_token_def] >>
fs [dfa_path_def, lexer_get_token_def] >>
every_case_tac >>
fs [] >>
rw [] >>
fs [] >>
metis_tac [APPEND_NIL]);

val dfa_maximal_path_extension_lem = Q.prove (
`!s.
  ?path state s'.
    dfa_path trans start state path ∧
    (s = MAP FST path ++ s') ∧
    ((s' = []) ∨ (?c s''. (s' = c::s'') ∧ (FLOOKUP trans (state,c) = NONE)))`,
induct_on `LENGTH s` >>
rw [] >|
[cases_on `s` >>
     fs [dfa_path_def],
 `s ≠ []` by (cases_on `s` >> fs []) >>
     `?s1 c. s = s1 ++ [c]` by metis_tac [split_end] >>
     rw [] >>
     fs [] >>
     `v = LENGTH s1` by decide_tac >>
     fs [] >>
     rw [] >>
     POP_ASSUM (fn _ => all_tac) >>
     POP_ASSUM (STRIP_ASSUME_TAC o Q.SPEC `s1`) >>
     fs [] >>
     rw [] >|
     [cases_on `FLOOKUP trans (state,c)` >-
          metis_tac [] >>
          qexists_tac `path++[(c,x)]` >>
          rw [] >>
          metis_tac [dfa_path_extend],
      metis_tac [APPEND, APPEND_ASSOC]]]);

val dfa_maximal_path_extension = Q.prove (
`!trans start s.
  ?path state s'.
    dfa_path trans start state path ∧
    (s = MAP FST path ++ s') ∧
    ((s' = []) ∨ (?c s''. (s' = c::s'') ∧ (FLOOKUP trans (state,c) = NONE)))`,
metis_tac [dfa_maximal_path_extension_lem]);

val lexer_get_token_complete = Q.prove (
`∀transition start state path tok finals s p1 p2 lexeme answer.
  (path ≠ []) ∧
  dfa_path transition start state path ∧
  (FLOOKUP finals state = SOME tok) ∧
  (∀path_extension state'.
    dfa_path transition state state' path_extension ∧
    (?s'. MAP FST path_extension ++ s' = s)
    ⇒
    EVERY (\extra_state. FLOOKUP finals extra_state = NONE)
          (MAP SND path_extension))
  ⇒
  (lexer_get_token transition finals start lexeme answer (MAP FST path++s) =
   SOME (tok, REVERSE (MAP FST path)++lexeme,s))`,
recInduct dfa_path_ind >>
rw [dfa_path_def] >>
every_case_tac >>
fs [] >>
rw [lexer_get_token_def] >>
cases_on `path = []` >>
fs [dfa_path_def] >>
rw [] >|
[cases_on `s` >>
     rw [lexer_get_token_def] >>
     cases_on `FLOOKUP trans (end_state,h)` >>
     rw [] >>
     `dfa_path trans end_state x [(h,x)]` by rw [dfa_path_def] >>
     res_tac >>
     fs [] >>
     STRIP_ASSUME_TAC (Q.SPECL [`trans`,`x`, `t`] dfa_maximal_path_extension) >>
     rw [] >>
     fs [] >>
     `dfa_path trans end_state state ((h,x)::path)` by rw [dfa_path_def] >>
     res_tac >>
     fs [] >>
     metis_tac [lexer_get_token_no_more_final,APPEND_NIL],
 metis_tac [APPEND, APPEND_ASSOC]]);

val get_token_size_lem = Q.prove (
`!trans finals start lexeme answer s tok lexeme' s'.
  ((answer = NONE) ∨ (?a b c. (answer = SOME (a,b,c)) ∧ b ≠ "")) ∧
  (lexer_get_token trans finals start lexeme answer s = SOME (tok,lexeme',s'))
  ⇒
  (lexeme' ≠ [])`,
induct_on `s` >>
rw [lexer_get_token_def] >>
every_case_tac >>
fs [] >>
`STRING h lexeme ≠ ""` by fs [] >>
metis_tac []);

val lexer_def = tDefine "lexer" `
(lexer (trans,finals,start) [] acc = SOME (REVERSE acc)) ∧
(lexer (trans,finals,start) (c::cs) acc =
  case lexer_get_token trans finals start "" NONE (c::cs) of
    | NONE => NONE
    | SOME (f,lexeme,s') =>
        lexer (trans,finals,start) s' (f (REVERSE lexeme)::acc))`
(WF_REL_TAC `measure (\(x,y,z). STRLEN y)` >>
 rw [] >>
 `lexer_get_token_invariant trans finals start start "" NONE (STRING c cs)`
           by metis_tac [lexer_get_token_invariant_initial] >>
 imp_res_tac lexer_get_token_partial_correctness >>
 fs [] >>
 `STRLEN (STRING c cs) = STRLEN (MAP FST path' ++ p_2)`
           by metis_tac [lexer_get_token_partial_correctness] >>
 fs [] >>
 cases_on `path'` >>
 fs [dfa_path_def] >>
 rw [] >>
 imp_res_tac get_token_size_lem >>
 fs []);

val lexer_ind = fetch "-" "lexer_ind";

val dfa_correct_def = Define `
dfa_correct lexer_spec trans finals start =
  ∀l t.
    (?p s.
      (l = MAP FST p) ∧ dfa_path trans start s p ∧ (FLOOKUP finals s = SOME t))
    =
    ∃n.
      n < LENGTH lexer_spec ∧
      (SND (EL n lexer_spec) = t) ∧
      (regexp_matches (FST (EL n lexer_spec)) l) ∧
      (∀n'. n' < n ⇒ ¬regexp_matches (FST (EL n' lexer_spec)) l)`;

val lexer_acc_thm = Q.prove (
`!trans finals start s acc res.
  (lexer (trans,finals,start) s acc = SOME res)
  ⇒
  (∃toks'. res = REVERSE acc ++ toks')`,
recInduct lexer_ind >>
rw [lexer_def] >>
every_case_tac >>
fs [] >>
res_tac >>
fs []);

val lexer_acc_thm2 = Q.prove (
`!trans finals start s acc1 acc2 res x.
  (lexer (trans,finals,start) s (acc1++acc2) =
    SOME (REVERSE (acc1++acc2) ++ res))
  ⇒
  (lexer (trans,finals,start) s (acc1++x::acc2) =
    SOME (REVERSE (acc1++x::acc2)++res))`,
recInduct lexer_ind >>
rw [lexer_def] >>
every_case_tac >>
fs [] >>
`?toks. REVERSE (acc ++acc2) ++ res = REVERSE (q (REVERSE q')::(acc++acc2)) ++ toks`
           by metis_tac [lexer_acc_thm] >>
fs [] >>
rw [] >>
metis_tac [APPEND, APPEND_ASSOC]);

val lexer_partial_correctness_lem1 = Q.prove (
`!s1 l s2 s3.
  STRLEN s1 < LENGTH l ∧ (s1 ++ s2 = MAP FST l ++ s3)
  ⇒
  (?l' l''. (l = l' ++ l'') ∧ (s1 = MAP FST l'))`,
induct_on `s1` >>
rw [] >>
cases_on `l` >>
rw [] >>
fs [] >>
rw [] >>
res_tac >>
rw [] >>
qexists_tac `h'::l'` >>
rw []);

val lexer_partial_correctness = Q.prove (
`!trans finals start s acc lexer_spec toks.
  dfa_correct lexer_spec trans finals start ∧
  (lexer (trans,finals,start) s acc = SOME (REVERSE acc++toks))
  ⇒
  correct_lex lexer_spec s toks`,
recInduct lexer_ind >>
rw [lexer_def] >-
rw [correct_lex_def] >>
every_case_tac >>
fs [] >>
imp_res_tac lexer_acc_thm >>
fs [] >>
rw [] >>
`correct_lex lexer_spec r' toks'`
             by metis_tac [APPEND_ASSOC, APPEND] >>
rw [correct_lex_def] >>
`?state path.
 dfa_path trans start state path ∧
 (REVERSE q' = MAP FST path) ∧
 (FLOOKUP finals state = SOME q) ∧
 (STRCAT (REVERSE q') r' = STRCAT (REVERSE "") (STRING c cs)) ∧
 (∀path_extension state'.
    dfa_path trans state state' path_extension ∧
    (∃s''. STRCAT (MAP FST path_extension) s'' = r') ⇒
    EVERY (λextra_state. FLOOKUP finals extra_state = NONE)
      (MAP SND path_extension))`
             by metis_tac [lexer_get_token_partial_correctness,
                           lexer_get_token_invariant_initial] >>
fs [] >>
`?n. n < LENGTH lexer_spec ∧ (SND (EL n lexer_spec) = q) ∧
     regexp_matches (FST (EL n lexer_spec)) (MAP FST path) ∧
     (!n'. n' < n ⇒ ~regexp_matches (FST (EL n' lexer_spec)) (MAP FST path))`
             by metis_tac [dfa_correct_def] >>
rw [lexer_spec_matches_prefix_def] >>
qexists_tac `REVERSE q'` >>
qexists_tac `n` >>
qexists_tac `r'` >>
rw [] >|
[metis_tac [get_token_size_lem],
 cases_on  `(EL n lexer_spec)` >>
     fs [] >>
     metis_tac [],
 `?n_min.
    (?r_min tok_min.
       n_min < LENGTH lexer_spec ∧
       (EL n_min lexer_spec = (r_min,tok_min)) ∧
       regexp_matches r_min lexeme') ∧
    (!n_min'. n_min' < n_min ⇒
       ¬(?r_min tok_min.
            (EL n_min' lexer_spec = (r_min,tok_min)) ∧
            regexp_matches r_min lexeme'))`
        by (imp_res_tac ((Q.SPEC `r` o
                          SIMP_RULE (srw_ss())
                              [METIS_PROVE [] ``(?x. P x) ⇒ Q = !x. P x ⇒ Q``] o
                          Q.SPECL [`\n_min. ?r_min tok_min.
                                      n_min < LENGTH lexer_spec ∧
                                      (EL n_min lexer_spec = (r_min,tok_min)) ∧
                                      regexp_matches r_min lexeme'`,
                                   `n'`])
                                  min_lem) >>
            qexists_tac `n''` >>
            rw [] >>
            metis_tac [arithmeticTheory.LESS_TRANS]) >>
     fs [] >>
     `!n_min'. n_min' < n_min ⇒ ~regexp_matches (FST (EL n_min' lexer_spec)) lexeme'`
              by (rw [] >>
                  cases_on `EL n_min' lexer_spec` >>
                  rw [] >>
                  metis_tac []) >>
     `?p s.
       (lexeme' = MAP FST p) ∧ dfa_path trans start s p ∧
       (FLOOKUP finals s = SOME tok_min)`
                by metis_tac [dfa_correct_def, FST, SND] >>
     fs [] >>
     rw [] >>
     CCONTR_TAC >>
     fs [arithmeticTheory.NOT_LESS_EQUAL] >>
     `?path' path_extension.
        (p = path' ++ path_extension) ∧
        (LENGTH (REVERSE q') = LENGTH path')`
             by metis_tac [LENGTH_MAP, LENGTH_REVERSE,
                           lexer_partial_correctness_lem1] >>
     fs [] >>
     rw [] >>
     `STRLEN (REVERSE q') = STRLEN (MAP FST path')` by rw [] >>
     `(REVERSE q' = MAP FST path') ∧ (r' = MAP FST path_extension ++ s_rest')`
               by metis_tac [strcat_lem, STRCAT_ASSOC] >>
     fs [dfa_path_append] >>
     rw [] >>
     `(path = path') ∧ (state = s')` by metis_tac [dfa_path_determ] >>
     rw [] >>
     `EVERY (λextra_state. FLOOKUP finals extra_state = NONE)
          (MAP SND path_extension)`
                by metis_tac [] >>
     `path_extension ≠ []`
             by (cases_on `path_extension` >>
                 fs []) >>
     imp_res_tac dfa_path_last >>
     fs [] >>
     rw [],
 CCONTR_TAC >>
     fs [arithmeticTheory.NOT_LESS_EQUAL] >>
     metis_tac [FST, strcat_lem, LENGTH_MAP, LENGTH_REVERSE]]);

val lexer_complete_lem1 = Q.prove (
`!trans finals start s1 s2 acc.
  (s1 ≠ "")
  ⇒
  (lexer (trans,finals,start) (s1++s2) acc =
    case lexer_get_token trans finals start "" NONE (s1++s2) of
      | NONE => NONE
      | SOME (tok,lexeme,s') =>
          lexer (trans,finals,start) s' (tok (REVERSE lexeme)::acc))`,
cases_on `s1` >>
rw [lexer_def]);

val lexer_complete = Q.prove (
`!trans finals start s acc lexer_spec toks.
  dfa_correct lexer_spec trans finals start ∧
  correct_lex lexer_spec s toks
  ⇒
  (lexer (trans,finals,start) s acc = SOME (REVERSE acc++toks))`,
induct_on `toks` >>
rw [correct_lex_def, lexer_def] >>
fs [correct_lex_def, lexer_spec_matches_prefix_def] >>
`lexer (trans,finals,start) s_rest acc = SOME (REVERSE acc ++ toks)`
      by metis_tac [] >>
rw []>>
`!n'. n' < n ⇒ ~regexp_matches (FST (EL n' lexer_spec)) lexeme`
              by (rw [] >>
                  cases_on `EL n' lexer_spec` >>
                  rw [] >>
                  metis_tac [arithmeticTheory.LESS_TRANS,
                             arithmeticTheory.NOT_LESS_EQUAL]) >>
`?p state. (lexeme = MAP FST p) ∧ dfa_path trans start state p ∧
       (FLOOKUP finals state = SOME f)`
            by metis_tac [FST, SND, dfa_correct_def] >>
rw [lexer_complete_lem1] >>
cases_on `p = []` >>
fs [] >>
cases_on `
      ∀path_extension state'.
        dfa_path trans state state' path_extension ∧
        (∃s'. MAP FST path_extension ++ s' = s_rest) ⇒
        EVERY (λextra_state. FLOOKUP finals extra_state = NONE)
          (MAP SND path_extension)` >>
fs [] >|
[imp_res_tac lexer_get_token_complete >>
     rw [] >>
     metis_tac [lexer_acc_thm2, APPEND, APPEND_ASSOC, REVERSE_DEF],
 fs [combinTheory.o_DEF, EXISTS_MAP] >>
     imp_res_tac exists_split >>
     PairCases_on `x` >>
     fs [dfa_path_append, dfa_path_def] >>
     cases_on `FLOOKUP trans (s''',x0)` >>
     fs [] >>
     rw [] >>
     `dfa_path trans start s'' (p++l1++[(x0,s'')])`
             by metis_tac [dfa_path_extend, dfa_path_append] >>
     cases_on `FLOOKUP finals s''` >>
     fs [] >>
     `?n'. n' < LENGTH lexer_spec ∧ (SND (EL n' lexer_spec) = x) ∧
          regexp_matches (FST (EL n' lexer_spec)) (MAP FST (p++l1++[(x0,s'')]))`
              by metis_tac [dfa_correct_def] >>
     fs [] >>
     cases_on `EL n' lexer_spec` >>
     fs [] >>
     `¬(LENGTH (MAP FST p ++ MAP FST l1 ++ [x0]) ≤ LENGTH p)`
              by (rw [] >> decide_tac) >>
     metis_tac [APPEND_ASSOC]]);

val lexer_correct = Q.store_thm ("lexer_correct",
`!lexer_spec trans finals start.
  dfa_correct lexer_spec trans finals start
  ⇒
  (!s toks.
     correct_lex lexer_spec s toks =
     (lexer (trans,finals,start) s [] = SOME toks))`,
metis_tac [lexer_complete, lexer_partial_correctness, APPEND, REVERSE_DEF]);

val _ = export_theory ();
