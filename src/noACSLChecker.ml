open GenericNFRChecker
open Cil_types

class noACSLChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "noACSLChecker"

  method noACSLInFunspec s = 
      List.is_empty s.spec_behavior &&
      Option.is_none s.spec_variant &&
      Option.is_none s.spec_terminates &&
      List.is_empty s.spec_complete_behaviors &&
      List.is_empty s.spec_disjoint_behaviors
    
  method! vglob_aux g = match g with
    | GAnnot (ga, loc) -> 
        self#print_error ~loc:loc 
          (Format.asprintf "Found global ACSL annotation %a" Printer.pp_global_annotation ga);
        Cil.SkipChildren
    | _ -> Cil.DoChildren

  method! vstmt_aux sk = match sk.skind with
    | _ -> Cil.DoChildren

  method! vspec spec =
    if not (self#noACSLInFunspec spec) then
      (let name =
        match self#current_kf with
        | Some kf -> Kernel_function.get_name kf
        | None -> "<unknown>"
      in
      self#print_error
        (Format.asprintf "Found ACSL function contract for %s" name));
    Cil.SkipChildren

  method! vcode_annot ca =
    let loc =
      Option.value ~default:Fileloc.unknown
        (Cil_datatype.Code_annotation.loc ca)
    in
    let description =
      match self#current_stmt with
      | Some { skind = Loop _; _ } -> "loop ACSL annotation"
      | _ -> "statement ACSL annotation"
    in
    self#print_error ~loc
      (Format.asprintf "Found %s %a" description Printer.pp_code_annotation ca);
    Cil.SkipChildren

  end