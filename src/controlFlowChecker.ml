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
      (* TODO: Check also for GFun *)
      | GFunDecl(_, vi, loc) when not(vi_is_static vi) -> 
        (if not(viInList vi entry_vis) then 
          self#print_error (Format.asprintf "The function %a is declared as non-static but not in the list \
            of entry functions" Printer.pp_varinfo vi) ~loc:loc 
        else
          Self.debug ~level:3 "The function %a is declared and is in the list"
            Printer.pp_varinfo vi);  
        Cil.SkipChildren
      | GFun({svar = vi; _}, loc) when not (vi_is_static vi) -> 
        (if not(viInList vi entry_vis) then 
          self#print_error (Format.asprintf "The function %a is defined as non-static but not in the list \
            of entry functions" Printer.pp_varinfo vi) ~loc:loc 
        else
          Self.debug ~level:3 "The function %a is defined and is in the list"
            Printer.pp_varinfo vi);  
        Cil.SkipChildren
      | _ -> Cil.SkipChildren
end


class whiteListFunCallsChecker ispec = object (self)
  inherit genericNFRChecker ispec
  method name = "whiteListFunCallsChecker"

  method private check_vi ?(loc = unknown_loc) vi =  
    if not(vi_is_static vi) && not(viInList vi (self#get_callable_vis ()))  then 
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
  method !vexpr e = match e.enode with 
    | Lval(Var(vi), _) ->
      (if Ast_types.is_fun_ptr vi.vtype then 
        self#print_error 
          ~loc:e.eloc (Format.asprintf "Found expression containing \
                        a function pointer %a" Printer.pp_varinfo vi));
        Cil.SkipChildren
    | AddrOf(Var(vi), _) -> 
      (if Ast_types.is_fun vi.vtype then 
        self#print_error 
          ~loc:e.eloc (Format.asprintf "Found expression containing \
                        the address of a function: %a" Printer.pp_varinfo vi));
        Cil.SkipChildren
    | _ -> Cil.DoChildren
  (* method !vinst i = match i with 
    | Call(_, e, pexps, loc) -> 
        (match unroll_call_exp e with
          | Some(Mem(_)) -> 
            self#print_error 
              ~loc:loc (Format.asprintf "Found function call to a function pointer: %a" Printer.pp_exp e)
          | _ ->  ());
        Cil.SkipChildren
    | _ -> Cil.DoChildren *)
  (*NOTE: We dont have to check at local_inits, as calls to function pointers are moved from local inits
            during Frama-C normalization (or maybe preprocessing)
  **)

end

(** Checks that there are no function definitions in h-files. *)
class noFunctionDefsChecker ispec = object (self)
  inherit genericNFRChecker ispec
  (* Change so that this always checks, so user must run it only on h-files *)
  method name = "NoFunctionDefinitionsChecker"
  method !vglob_aux i = match i with 
    | GFun (fd, loc) -> 
        (self#print_error
          ~loc:loc (Format.asprintf "Found function definition: %a" Printer.pp_varinfo fd.svar));
        Cil.SkipChildren
        
      | _ -> Cil.SkipChildren
  (*NOTE: We dont have to check at local_inits, as calls to function pointers are moved from local inits
            during Frama-C normalization (or maybe preprocessing)
  **)

end

class noPtrArithmeticsChecker ispec = object (self)
  inherit genericNFRChecker ispec
  (* Change so that this always checks, so user must run it only on h-files *)
  method name = "PtrArithmeticsChecker"
  method !vexpr e = match e.enode with 
    | BinOp(_, _, _, t) -> 
        if Ast_types.is_ptr t then 
          self#print_error
            ~loc:e.eloc (Format.asprintf "Found pointer arithmetic expression: %a" Printer.pp_exp e);
        Cil.DoChildren
    | _ -> Cil.DoChildren

end 