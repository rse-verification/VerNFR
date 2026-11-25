open GenericNFRChecker
open Cil_types

let allowedACSLCategories =
  [ "assert"; "loop-invariant"; "loop-assigns"; "loop-variant";
    "lemma"; "predicate"; "logic-function" ]

class noACSLChecker ispec = object (self)
  inherit genericNFRChecker ispec as super

  method name = "noACSLChecker"

  method noACSLInFunspec s = 
      List.is_empty s.spec_behavior &&
      Option.is_none s.spec_variant &&
      Option.is_none s.spec_terminates &&
      List.is_empty s.spec_complete_behaviors &&
      List.is_empty s.spec_disjoint_behaviors

  (** global annotations, we allow lemmas, functions and predicates*)
  method globalAnnotationCategory ga =
    match ga with
    | Dlemma (_, _, _, tp, _, _) when tp.tp_kind <> Admit -> Some "lemma"
    | Dfun_or_pred ({ l_type = None; _ }, _) -> Some "predicate"
    | Dfun_or_pred _ -> Some "logic-function"
    | _ -> None

  method isAllowedGlobalAnnotation ga =
    match self#globalAnnotationCategory ga with
    | Some c -> Options.AllowedACSL.mem c
    | None ->
        match ga with
        | Daxiomatic (_, l, _, _)
        | Dmodule (_, l, _, _, _) ->
            List.for_all self#isAllowedGlobalAnnotation l
        | _ -> false

  method! vglob_aux g = match g with
    | GAnnot (ga, loc) when not (self#isAllowedGlobalAnnotation ga) ->
        self#print_error ~loc:loc 
          (Format.asprintf "Found global ACSL annotation %a" Printer.pp_global_annotation ga);
        Cil.SkipChildren
    | GAnnot _ -> Cil.SkipChildren
    | _ -> Cil.DoChildren

  method! vvdec vi =
    if vi.vghost then
      self#print_error ~loc:vi.vdecl
        (Format.asprintf "Found ghost declaration %a" Printer.pp_varinfo vi);
    Cil.DoChildren

  method! vstmt_aux stmt =
    if stmt.ghost then
      self#print_error ~loc:(Cil_datatype.Stmt.loc stmt)
        "Found ghost statement";
    Cil.DoChildren

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

  (* Whitelist categories for code annotations (-nfr-acsl-allow). Only
     annotations that WP must prove before using them (obligations) can be
     whitelisted; annotations with the admit modifier are assumptions and
     are never allowed. *)
  method acslInCodeCategory ca =
    let not_admit tp = tp.tp_kind <> Admit in
    match ca.annot_content with
    | AAssert (_, tp) when not_admit tp -> Some "assert"
    | AInvariant (_, true, tp) when not_admit tp -> Some "loop-invariant"
    | AAssigns _ -> Some "loop-assigns"
    | AVariant _ -> Some "loop-variant"
    | _ -> None

  method isAllowed ca =
    match self#acslInCodeCategory ca with
    | Some c -> Options.AllowedACSL.mem c
    | None -> false

  method! run () =
    let unknown =
      Options.AllowedACSL.fold
        (fun c acc -> if List.mem c allowedACSLCategories then acc else c :: acc)
        []
    in
    if unknown <> [] then
      Options.Self.abort "unknown ACSL categories for -nfr-acsl-allow: %s (known: %s)"
        (String.concat ", " (List.rev unknown))
        (String.concat ", " allowedACSLCategories);
    super#run ()

  method! vcode_annot ca =
    if self#isAllowed ca then Cil.SkipChildren else
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
