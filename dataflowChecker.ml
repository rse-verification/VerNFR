open Options

class verifyVarsAreStatic = object
  inherit Visitor.frama_c_inplace

  method !vglob_aux g = 
    let () = match g with 
      | GVar(vi, _, _) | GVarDecl(vi, _) ->
        (match vi.vstorage with 
          | Static -> Self.debug ~level:3 "Variable %a has static storage" Printer.pp_varinfo vi
          | _ -> Self.feedback "Variable %a does not have static storage" Printer.pp_varinfo vi)
      | _ -> ()
    in
    Cil.SkipChildren
end