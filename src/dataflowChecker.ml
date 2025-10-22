open Options
open GenericNFRChecker


class verifyVarsAreStatic ispec = object
  inherit genericNFRChecker ispec

  method name = "StaticVariableChecker"

  method !vglob_aux g = 
    let () = match g with 
      | GVar(vi, _, _) | GVarDecl(vi, _) ->
        (match vi.vstorage with 
          | Static -> Self.debug ~level:3 "Variable %a has static storage" Printer.pp_varinfo vi
          | _ -> Self.warning "Variable %a does not have static storage" Printer.pp_varinfo vi)
      | _ -> ()
    in
    Cil.SkipChildren
end

