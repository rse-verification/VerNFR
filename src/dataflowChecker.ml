open Options
open GenericNFRChecker
open Cil_types


class verifyVarsAreStatic ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "StaticVariableChecker"

  method !vglob_aux (g: Cil_types.global) = 
    let () = match g with 
      | GVar(vi, _, loc) | GVarDecl(vi, loc) ->
        (match vi.vstorage with 
          | Static -> Self.debug ~level:3 "Variable %a has static storage" Printer.pp_varinfo vi
          | _ -> self#print_error 
            ~loc:loc (Format.asprintf "Variable %a does not have static storage" Printer.pp_varinfo vi))
      | _ -> ()
    in
    Cil.SkipChildren
end

class properInitChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "properInitChecker"

  (* method get_all_inouts () =
    let actual_entry = (Globals.entry_point ()) in *)
    (* let make_inout_for_fn kf iomap = 
      begin
        Globals.set_entry_point (Kernel_function.get_name kf) false;
        Eva.Engine.Analysis.force_compute ();
        Kernel_function.Map.add kf (Inout.get_precise_inout kf) iomap
      end
    in
    let iomap = Globals.Functions.fold make_inout_for_fn Kernel_function.Map.empty in
    Globals.set_entry_point 
      (fst (Kernel_function.get_name actual_entry)) 
      (snd actual entry);
    iomap *)

  method !vfile f = 
    (* Ast.compute (); *)
    let ispec = Option.get self#ispec in
    let no_init_vars = List.fold_left
      (fun acc g -> match g with 
        | GVar(vi, {init = None}, _) -> Locations.Zone.join (Locations.zone_of_varinfo vi) acc
        | _ -> acc  
      )
      Locations.Zone.bottom
      f.globals 
    in
    Self.feedback "getting inouts next";
    let all_inouts = 
      Globals.Functions.fold 
        (fun kf acc -> Kernel_function.Map.add kf (Inout.kf_external_outputs kf) acc)
        Kernel_function.Map.empty
    in
    let check_fn isd =  
      let entry_vi = self#vi_from_ispec_decl isd in
      match Utils.vi_to_kf_opt entry_vi with
        | None -> Self.debug ~level:3 "no entry function find for %a" Printer.pp_varinfo entry_vi
        | Some(entry_kf) -> 
        let pred_vis = 
          List.map self#vi_from_ispec_decl (Utils.ISDSet.to_list (Utils.get_fns_called_before isd ispec))
        in
        List.iter (fun x -> Self.debug ~level:5 "predvis: %a" Printer.pp_varinfo x) pred_vis;  

        (*Get predecessors outputs*)
        (*TODO: Do we care if some kf is not defined? (should be sound anyway)*)
        let pred_kfs = List.filter_map Utils.vi_to_kf_opt pred_vis in
        let pred_outs = List.fold_left
          (fun acc kf -> Locations.Zone.join 
            (Kernel_function.Map.find kf all_inouts) acc)
          Locations.Zone.bottom
          pred_kfs
        in
        (*Get current entry points inputs*)
        let entry_ins = Inout.kf_external_inputs entry_kf in
        (* we start with the global vars without explicit init, then we remove all 
          outputs for predecessor functions, and then take the intersection with the current entry
        *)
        let inputs_no_init = Locations.Zone.meet 
          entry_ins
          (Locations.Zone.diff no_init_vars pred_outs)
        in
        if Locations.Zone.is_bottom inputs_no_init then
          Self.feedback "All variables used have been initialised properly in %a"
            Printer.pp_varinfo entry_vi
        else 
          self#print_error (Format.asprintf "The following variables uses their \
            default value in %a: %a" 
            Printer.pp_varinfo (entry_vi)
            Locations.Zone.pretty inputs_no_init)

    in
    List.iter check_fn ispec.entry_fns;
    Cil.SkipChildren
        

    (* TODO:Continue here//;;; *)
end