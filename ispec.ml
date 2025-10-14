open Cil_types

type ispec_fn_type = fundec

type call_comparison_op = CalledBefore | CalledAfter

type order_constraint = CalledBefore of (ispec_fn_type * ispec_fn_type) |
                        CalledAfter of (ispec_fn_type * ispec_fn_type)

type restricted_include = {
  hfile: string;
  fns: ispec_fn_type list;
}

type call_restrictions = {
  includes: restricted_include list; 
  call_order: order_constraint list;
} 

type ispec = {
  entry_fns: ispec_fn_type list; 
  entry_order: order_constraint list;  
  extern_calls: call_restrictions list;
}

