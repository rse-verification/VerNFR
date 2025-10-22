open Cil_types

(*NOTE: a fundec has field .sspec,*)
type ispec_fn_type = fundec


type order_constraint = CalledBefore of (ispec_fn_type * ispec_fn_type) 
   (*| CalledAfter of (ispec_fn_type * ispec_fn_type) *)


type restricted_include = {
  hfile: string;
  fns: ispec_fn_type list;
}

type call_restrictions = {
  includes: restricted_include list; 
  call_order: order_constraint list; 
} 

(*Control flow*)
type ispec = {
  (* provides: *)
    entry_fns: ispec_fn_type list; 
  (* requires: *)
    entry_order: order_constraint list;  (*required entry order*)
  (* ensures: *)
    extern_calls: call_restrictions;
}
