open Options
open Cil_types 
open GenericNFRChecker
open Ispec

let viEq vi1 vi2 = (Cil.areCompatibleTypes vi1.vtype vi2.vtype) && vi1.vname = vi2.vname
let viInList vi = List.exists (fun vi' -> viEq vi vi')


class onlyEntryPointsDeclaredChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "onlyEntryPointsDeclaredChecker"
  method !vglob_aux g = 
    let entry_vis = (List.map (fun x -> x.svar) self#ispec.entry_fns) in
    match g with
      | GFunDecl(_, vi, _) -> 
        (if not(viInList vi entry_vis) then 
          Self.warning "The function %a is declared but not in the list \
            of entry functions" Printer.pp_varinfo vi
        else
          Self.debug ~level:3 "The function %a is declared and is in the list"
            Printer.pp_varinfo vi);  
        Cil.SkipChildren
      | _ -> Cil.SkipChildren

end


class whiteListFunCallsChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "whiteListFunCallsChecker"
  method !vinst i = 
    let whitelist_vis = List.concat_map (fun restr_inc -> List.map (fun x -> x.svar) restr_inc.fns)
      self#ispec.extern_calls.includes in
    let unroll_call_exp e = match e.enode with 
      | Lval((lh, _)) -> (match lh with
        | Var(vi) -> Some(vi)
        | _ -> 
          Self.debug ~level:3 "mem lval in call exp: %a" Printer.pp_exp e;
          None
      )
        
      | _ -> 
          Self.debug ~level:3 "not an lval in a call exp: %a" Printer.pp_exp e;
          None
    in
    let is_static vi = match vi.vstorage with | Static -> true | _ -> false in
    match i with 
      | Call(_, e, _, _) -> (match unroll_call_exp e with  
          | Some(vi) -> if not(is_static vi) && not(viInList vi whitelist_vis)  then 
              Self.warning "Function call to %a, which is not in the whitelist" 
                Printer.pp_varinfo vi
              else 
                Self.debug ~level:3 "Function call to %a (which is in the whitelist)" 
                  Printer.pp_varinfo vi
          | None -> 
              Self.warning "found memory lval in function call instruction: %a" 
                Printer.pp_exp e 
        );
        Cil.SkipChildren
      (* | Set()
        Cil.SkipChildren *)
      | _ -> Cil.DoChildren

end

(* let isFunctionPtrType t = match Ast_types.unroll t with 
  (| TPtr(t') -> match Ast_types.unroll t' with
        | TFun(_) -> true
        | -> false)
  | _ -> false 
(*  *)
class noFunctionPointerChecker = object 
  inherit Visitor.frama_c_inplace
    
  method !vterm_node tn = 
    if is

end *)