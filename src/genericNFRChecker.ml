open Options

class virtual genericNFRChecker ispec = object (self)
  inherit Visitor.frama_c_inplace
  method virtual name : string
  method ispec: Ispec.ispec = ispec
  method run () = 
    Self.feedback "Running %s" self#name; 
    Visitor.visitFramacFileSameGlobals (self :> Visitor.frama_c_inplace) (Ast.get ())

end