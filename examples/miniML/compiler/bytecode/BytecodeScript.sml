(* generated by Lem from bytecode.lem *)
open bossLib Theory Parse res_quanTheory
open finite_mapTheory listTheory pairTheory pred_setTheory integerTheory
open set_relationTheory sortingTheory stringTheory wordsTheory

val _ = new_theory "Bytecode"

(* --- Syntax --- *)

val _ = Hol_datatype `

  bc_stack_op =
    Pop                     (* pop top of stack *)
  | Pops of num             (* pop n elements under stack top *)
  | PushInt of int          (* push num onto stack *)
  | Cons of num => num       (* push new cons with tag m and n elements *)
  | Load of num             (* push stack[n+1] *)
  | Store of num            (* pop and store in stack[n+1] *)
  | El of num               (* read field n of cons block *)
  | TagEquals of num        (* test tag from cons block or number *)
  | IsNum | Equal           (* tests *)
  | Add | Sub | Mult | Div2 | Mod2 | Less`;
  (* arithmetic *)

val _ = Hol_datatype `

  bc_inst =
    Stack of bc_stack_op
  | Jump of num             (* jump to location n *)
  | JumpNil of num          (* conditional jump to location n *)
  | Call of num             (* call location n *)
  | JumpPtr                 (* jump based on code pointer *)
  | CallPtr                 (* call based on code pointer *)
  | Return                  (* pop return address, jump *)
  | Exception               (* restore stack, jump *)
  | Ref                     (* create a new ref cell *)
  | Deref                   (* dereference a ref cell *)
  | Update`;
                  (* update a ref cell *)

(* Semantics *)

(*val num_to_int : num -> Int.int*)

 val bool_to_int_defn = Hol_defn "bool_to_int" `

(bool_to_int T = & 1)
/\
(bool_to_int F = & 0)`;

val _ = Defn.save_defn bool_to_int_defn;
val _ = export_theory()

