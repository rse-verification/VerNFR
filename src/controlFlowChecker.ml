open Options
open Cil_types 
open GenericNFRChecker
open Ispec

let viEq vi1 vi2 = (Cil.areCompatibleTypes vi1.vtype vi2.vtype) && vi1.vname = vi2.vname
let viInList vi = List.exists (fun vi' -> viEq vi vi')

let unroll_call_exp e = 
  match e.enode with 
    | Lval((lh, _)) -> Some(lh)
    | _ -> 
        Self.debug ~level:3 "not an lval in a call exp: %a" Printer.pp_exp e;
        None

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

  method private is_static vi = match vi.vstorage with | Static -> true | _ -> false
  method private get_whitelist () =  
    List.concat_map (fun restr_inc -> List.map (fun x -> x.svar) restr_inc.fns)
      self#ispec.extern_calls.includes
  
  method private check_vi vi =  
    if not(self#is_static vi) && not(viInList vi (self#get_whitelist ()))  then 
      Self.warning "Function call to %a, which is not in the whitelist" 
        Printer.pp_varinfo vi
    else 
      Self.debug ~level:3 "Function call to %a (which is in the whitelist)" 
        Printer.pp_varinfo vi

  (*First argument is the vi being assigned to, ignore for now*)
  method !vlocal_init _ li = match li with 
    | ConsInit(vi, _, _) -> self#check_vi vi; Cil.SkipChildren
    | AssignInit(_) -> Cil.SkipChildren
    
  method !vinst i = 
    match i with 
      | Call(_, e, _, _) -> 
        (match unroll_call_exp e with
          | Some(Var(vi)) -> self#check_vi vi
          | Some(Mem(_)) -> 
            Self.debug ~level:3 "mem lval in call exp: %a" Printer.pp_exp e
          | _ ->  ());
        Cil.SkipChildren
      (* | Set()
        Cil.SkipChildren *)
      | _ -> Cil.DoChildren
  
end



(* let isFunctionPtrType t = match Ast_types.unroll t with 
  (| TPtr(t') -> match Ast_types.unroll t' with
        | TFun(_) -> true
        | -> false)
  | _ -> false  *)
(*  *)
class noFunctionPointerChecker ispec = object 
  inherit genericNFRChecker ispec

  method name = "NoFunctionPointersChecker"
  method !vinst i = match i with 
    | Call(_, e, _, _) -> 
        (match unroll_call_exp e with
          | Some(Mem(_)) -> 
            Self.warning "Found function call to a function pointer: %a" Printer.pp_exp e
          | _ ->  ());
        Cil.SkipChildren
      | _ -> Cil.DoChildren
  (*NOTE: We dont have to check at local_inits, as calls to function pointers are moved from local inits
            during Frama-C normalization (or maybe preprocessing)
  **)

end