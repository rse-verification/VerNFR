open Ispec 
open DataflowChecker 
open ControlFlowChecker
(* open GenericNFRChecker *)
open Options
(* open Cil_types *)

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
  entry_fns = [finit_fd; f10ms_fd];
  entry_order = [test_entry];
  extern_calls = test_call_restrictions;
}


(* TODO: Make this better with a class for checkers *)
(* 
let checkStaticVars () = 
  Self.feedback "Checking static vars";
  Visitor.visitFramacFileSameGlobals (new verifyVarsAreStatic) (Ast.get ())

let checkEntryFns entry_fns = 
  Self.feedback "Checking entry functions";
  Visitor.visitFramacFileSameGlobals 
    (new onlyEntryPointsDeclaredChecker (List.map (fun x -> x.svar) entry_fns)) (Ast.get ())

let checkOutgoingCalls ext_calls = 
  Self.feedback "Checking outgoing calls";
  let whitelist = List.flatmap (fun restr_inc -> restr_inc.fns) ext_calls.includes in
  Visitor.visitFramacFileSameGlobals
    (new whiteListFunCallsChecker whitelist) (Ast.get ()) *)


(* Replace with whatever spec you want to test, should in the future be parsed from input file *)
let get_ispec () = test_spec

let run () = 
  if Enabled.get () then
    let ispec = get_ispec () in
    begin
      (if CheckStatic.get () || CheckAll.get () then   
        (new verifyVarsAreStatic ispec)#run ());
      (if CheckEntry.get () || CheckAll.get () then 
        (new onlyEntryPointsDeclaredChecker ispec)#run ());
      (if CheckCalls.get () || CheckAll.get () then 
        (new whiteListFunCallsChecker ispec)#run ())
    end
  else ()
let () = Boot.Main.extend run





