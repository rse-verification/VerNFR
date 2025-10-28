open Options
open Cil_types 
open GenericNFRChecker
(* open Parser_lib.Ispec *)
open Utils


class onlyEntryPointsDeclaredChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "onlyEntryPointsDeclaredChecker"
  method !vglob_aux g = 
    let entry_vis = self#get_entry_vis () in
    match g with
      | GFunDecl(_, vi, loc) -> 
        (if not(viInList vi entry_vis) then 
          self#print_error (Format.asprintf "The function %a is declared but not in the list \
            of entry functions" Printer.pp_varinfo vi) ~loc:loc 
        else
          Self.debug ~level:3 "The function %a is declared and is in the list"
            Printer.pp_varinfo vi);  
        Cil.SkipChildren
      | _ -> Cil.SkipChildren

end


class whiteListFunCallsChecker ispec = object (self)
  inherit genericNFRChecker ispec
  method name = "whiteListFunCallsChecker"

  method private is_static vi = match vi.vstorage with | Static -> true | _ -> false
  
  method private check_vi ?(loc = unknown_loc) vi =  
    if not(self#is_static vi) && not(viInList vi (self#get_callable_vis ()))  then 
      self#print_error ~loc:loc (Format.asprintf "Function call to %a, which is not in the whitelist" 
        Printer.pp_varinfo vi)
    else 
      Self.debug ~level:3 "Function call to %a (which is in the whitelist)" 
        Printer.pp_varinfo vi
    
  method !vinst i = 
    match i with 
      | Call(_, e, _, loc) -> 
        (match unroll_call_exp e with
          | Some(Var(vi)) -> self#check_vi ~loc:loc vi
          | Some(Mem(_)) -> 
            Self.debug ~level:3 "mem lval in call exp: %a" Printer.pp_exp e
          | _ ->  ());
        Cil.SkipChildren
      (* | Set()
        Cil.SkipChildren *)
      | Local_init(_, li, loc) -> (match li with 
        | ConsInit(vi, _, _) -> self#check_vi ~loc:loc vi; Cil.SkipChildren
        | AssignInit(_) -> Cil.SkipChildren)
      | _ -> Cil.DoChildren
  
end



(* let isFunctionPtrType t = match Ast_types.unroll t with 
  (| TPtr(t') -> match Ast_types.unroll t' with
        | TFun(_) -> true
        | -> false)
  | _ -> false  *)
(*  *)
class noFunctionPointerChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "NoFunctionPointersChecker"
  method !vinst i = match i with 
    | Call(_, e, _, loc) -> 
        (match unroll_call_exp e with
          | Some(Mem(_)) -> 
            self#print_error 
              ~loc:loc (Format.asprintf "Found function call to a function pointer: %a" Printer.pp_exp e)
          | _ ->  ());
        Cil.SkipChildren
      | _ -> Cil.DoChildren
  (*NOTE: We dont have to check at local_inits, as calls to function pointers are moved from local inits
            during Frama-C normalization (or maybe preprocessing)
  **)

end