open Options
open Utils
open Parser_lib.Ispec

class virtual genericNFRChecker ispec = object (self)
  inherit Visitor.frama_c_inplace
  method virtual name : string
  method ispec: Parser_lib.Ispec.ispec = ispec

  val unknown_loc = Cil_datatype.Location.unknown

  method print_error ?(loc=unknown_loc) msg  = 
    Self.warning "%s (at %a)" msg Printer.pp_location loc

  method get_entry_vis () = 
    List.map varinfo_from_ispec_decl self#ispec.entry_fns

  method private get_callable_vis () =  
    List.concat_map 
      (fun restr_inc -> List.map varinfo_from_ispec_decl restr_inc.fns)
      self#ispec.extern_calls.includes
  

  method run () = 
    Self.feedback "Running %s" self#name; 
    Visitor.visitFramacFileSameGlobals (self :> Visitor.frama_c_inplace) (Ast.get ())

end