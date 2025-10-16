open Ispec 
open DataflowChecker 
open Options

let foo_fd = Cil.emptyFunction "foo" 
let bar_fd = Cil.emptyFunction "bar" 
let finit_fd = Cil.emptyFunction "f_init"
let f10ms_fd = Cil.emptyFunction "f_10ms"  
let test_entry = CalledBefore (finit_fd, f10ms_fd)

let test_restricted_include = {
  hfile = "mod.h";
  fns = [foo_fd; bar_fd];
}

let test_call_restrictions = {
  includes = [test_restricted_include];
  call_order = [];
} 

let test_spec = {
  entry_fns = [finit_fd];
  entry_order = [test_entry];
  extern_calls = [test_call_restrictions];
}


let run () = 
  if Enabled.get () then
    Visitor.visitFramacFileSameGlobals (new verifyVarsAreStatic) (Ast.get ())

let () = Boot.Main.extend run





