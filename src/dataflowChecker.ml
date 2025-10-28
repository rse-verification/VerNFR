open Options
open GenericNFRChecker


class verifyVarsAreStatic ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "StaticVariableChecker"

  method !vglob_aux g = 
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

