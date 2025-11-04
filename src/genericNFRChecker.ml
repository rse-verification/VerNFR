open Options
open Utils
open Parser_lib.Ispec

class virtual genericNFRChecker ispec = object (self)
  inherit Visitor.frama_c_inplace
  method virtual name : string
  method ispec: Parser_lib.Ispec.ispec option = ispec

  val unknown_loc = Cil_datatype.Location.unknown
  val mutable cil_file: Cil_types.file option = None
  val mutable entry_vis = None
  val mutable callable_vis = None

  method get_cil_file () = Option.get cil_file

  method vi_from_ispec_decl isd =
    (* let typ = ispec_decl_to_cil_type isd in *)
    (* (TODO: CHECK TYPE COMPATIBILITY) *)
    let vi_opt = List.find_map (fun (x:Cil_types.global) -> match x with
          | GFunDecl(_, vi, _) | GFun({svar=vi; _}, _) when vi.vname = isd.ispec_fname -> Some(vi)
          | _ ->  None)
        (self#get_cil_file ()).globals
    in
    match vi_opt with
      | Some(vi) -> 
        Self.debug ~level:4 "varinfo found for %a" Printer.pp_varinfo vi;
        vi
      | None ->
        (
          let ftyp = ispec_decl_to_cil_type isd in
          let vi = Cil.makeGlobalVar isd.ispec_fname ftyp in
          Self.debug ~level:3 "not varinfo found for %a, making a new" Printer.pp_varinfo vi;
          vi
        )



  method make_entry_vis () = 
    entry_vis <- 
      Some(
        List.map 
          self#vi_from_ispec_decl  
          (self#get_ispec ()).entry_fns
      )
  
  
  method make_callable_vis () = 
    callable_vis <- 
      Some(
        List.concat_map 
          (fun restr_inc -> List.map 
            self#vi_from_ispec_decl 
            restr_inc.fns)
          (self#get_ispec ()).extern_calls.includes
      )

  method get_ispec () = Option.get ispec

  method print_error ?(loc=unknown_loc) msg =
    if loc = unknown_loc then
      Self.warning "%s" msg
    else  
      Self.warning "%s (at %a)" msg Printer.pp_location loc

  method get_entry_vis () = Option.get entry_vis
  method private get_callable_vis () = Option.get callable_vis
  
  method run () = 
    Self.feedback "Running %s" self#name; 
    cil_file <- Some(Ast.get ());
    (if Option.is_some ispec then
      (self#make_entry_vis ();
      self#make_callable_vis ()));
    Visitor.visitFramacFileSameGlobals (self :> Visitor.frama_c_inplace) (self#get_cil_file ())

end