open Cil_types
open GenericNFRChecker
open Parser_lib.Ispec

module StringMap = Map.Make(String)
module StringSet = Set.Make(String)

type resolved_order_constraint = {
  lhs_decl: ispec_decl;
  rhs_decl: ispec_decl;
  (* CIL varinfos are what later instrumentation will match against at call
     sites. Keep the original declarations too, for diagnostics. *)
  lhs_vi: varinfo;
  rhs_vi: varinfo;
}

type entry_schedule =
  (* One topological order of the entry functions, compatible with entry_order.
     This will become the call sequence in the generated harness. *)
  | EntrySchedule of ispec_decl list
  (* If entry_order is cyclic, there is no meaningful harness order. *)
  | EntryOrderCycle of ispec_decl list

type ghost_call_var = {
  watched_decl: ispec_decl;
  ghost_vi: varinfo;
}

let decl_name decl = decl.ispec_fname

(* Ghost flag naming convention for a constraint lhs < rhs:
   "__nfr_<lhs>_called" records whether lhs has been called already. *)
let ghost_var_name decl =
  "__nfr_" ^ decl_name decl ^ "_called"

let ordered_insert decl decls =
  if List.exists (fun d -> decl_name d = decl_name decl) decls then decls
  else decls @ [decl]

let decrement_degree decl degrees =
  let name = decl_name decl in
  let degree = Option.value ~default:0 (StringMap.find_opt name degrees) in
  StringMap.add name (max 0 (degree - 1)) degrees

let entry_schedule_of_ispec spec =
  let entries = spec.entry_fns in
  (* Kahn-style topological sort over the entry_order partial order. The parser
     has already resolved names to declarations, so names are stable keys here
     and preserve the user-facing spelling. *)
  let initial_in_degree =
    List.fold_left
      (fun acc decl -> StringMap.add (decl_name decl) 0 acc)
      StringMap.empty
      entries
  in
  let add_edge (successors, degrees) = function
    | CalledBefore (lhs, rhs) ->
      let lhs_name = decl_name lhs in
      let rhs_name = decl_name rhs in
      let old_succs = Option.value ~default:[] (StringMap.find_opt lhs_name successors) in
      let edge_already_present =
        List.exists (fun succ -> decl_name succ = rhs_name) old_succs
      in
      let successors = StringMap.add lhs_name (ordered_insert rhs old_succs) successors in
      if edge_already_present then successors, degrees
      else
        let old_degree = Option.value ~default:0 (StringMap.find_opt rhs_name degrees) in
        successors, StringMap.add rhs_name (old_degree + 1) degrees
  in
  let successors, in_degree =
    List.fold_left add_edge (StringMap.empty, initial_in_degree) spec.entry_order
  in
  let zero_degree degrees =
    List.filter
      (fun decl ->
        Option.value ~default:0 (StringMap.find_opt (decl_name decl) degrees) = 0)
      entries
  in
  (* Pick the first not-yet-scheduled zero-degree entry in declaration order.
     That makes the generated harness deterministic for partial orders. *)
  let rec first_unscheduled_zero seen = function
    | [] -> None
    | decl :: rest ->
      if StringSet.mem (decl_name decl) seen then first_unscheduled_zero seen rest
      else Some decl
  in
  let rec loop seen degrees schedule =
    match first_unscheduled_zero seen (zero_degree degrees) with
    | None ->
      (* No schedulable entry remains. If the schedule is incomplete, the
         remaining nodes must be part of an entry_order cycle. *)
      if List.length schedule = List.length entries then
        EntrySchedule (List.rev schedule)
      else
        let cyclic =
          List.filter (fun decl -> not (StringSet.mem (decl_name decl) seen)) entries
        in
        EntryOrderCycle cyclic
    | Some decl ->
      let seen = StringSet.add (decl_name decl) seen in
      let succs = Option.value ~default:[] (StringMap.find_opt (decl_name decl) successors) in
      let degrees = List.fold_left (fun acc succ -> decrement_degree succ acc) degrees succs in
      loop seen degrees (decl :: schedule)
  in
  loop StringSet.empty in_degree []

let global_name_exists file name =
  List.exists
    (function
      | GVar (vi, _, _) | GVarDecl (vi, _) | GFun ({ svar = vi; _ }, _)
      | GFunDecl (_, vi, _) -> vi.vname = name
      | _ -> false)
    file.globals

let string_starts_with ~prefix s =
  let prefix_len = String.length prefix in
  String.length s >= prefix_len && String.sub s 0 prefix_len = prefix

let string_for_all pred s =
  let rec loop i =
    i = String.length s || (pred s.[i] && loop (i + 1))
  in
  loop 0

let is_generated_ghost_name base name =
  name = base ||
  let prefix = base ^ "_" in
  if not (string_starts_with ~prefix name) then false
  else
    let suffix =
      String.sub name (String.length prefix) (String.length name - String.length prefix)
    in
    suffix <> "" && string_for_all (fun c -> '0' <= c && c <= '9') suffix

(* Frama-C can run the plugin again after a -then. Reuse an already-generated
   ghost global so repeated runs do not produce __nfr_foo_called_1, _2, ... *)
let find_existing_ghost_var file decl =
  let base = ghost_var_name decl in
  List.find_map
    (function
      | GVar (vi, _, _) when vi.vghost && is_generated_ghost_name base vi.vname ->
        Some { watched_decl = decl; ghost_vi = vi }
      | _ -> None)
    file.globals

let rec fresh_global_name file base idx =
  let candidate =
    if idx = 0 then base else Format.sprintf "%s_%d" base idx
  in
  if global_name_exists file candidate then fresh_global_name file base (idx + 1)
  else candidate

(* Keep generated globals near the beginning of the file, before function
   declarations/definitions, so later annotations can refer to them normally. *)
let insert_global_before_code file global =
  let rec insert acc = function
    | [] -> List.rev_append acc [global]
    | ((GVar _ | GVarDecl _ | GFun _ | GFunDecl _) :: _) as tl ->
      List.rev_append acc (global :: tl)
    | hd :: tl -> insert (hd :: acc) tl
  in
  file.globals <- insert [] file.globals

let make_ghost_call_var file decl =
  match find_existing_ghost_var file decl with
  | Some var -> var
  | None ->
    let loc = Fileloc.unknown in
    let name = fresh_global_name file (ghost_var_name decl) 0 in
    let init = { init = Some (CInit (Cil.makeZeroInit ~loc Cil_const.intType)) } in
    let vi = Cil.makeGlobalVar ~ghost:true ~loc name Cil_const.intType in
    vi.vdefined <- true;
    (* Update both the visible AST and Frama-C's global variable table; plugins
       that query Globals.Vars should see the generated ghost as a normal global. *)
    Globals.Vars.add vi init;
    insert_global_before_code file (GVar (vi, init, loc));
    Ast.mark_as_grown ();
    { watched_decl = decl; ghost_vi = vi }

class externalCallOrderChecker ispec = object (self)
  inherit genericNFRChecker ispec

  method name = "externalCallOrderChecker"

  val mutable resolved_constraints: resolved_order_constraint list = []
  val mutable entry_schedule: entry_schedule option = None
  val mutable ghost_vars: ghost_call_var StringMap.t = StringMap.empty

  method resolved_constraints = resolved_constraints
  method entry_schedule = entry_schedule
  method ghost_vars = ghost_vars

  method private resolve_order_constraint = function
    | CalledBefore (lhs, rhs) ->
      {
        lhs_decl = lhs;
        rhs_decl = rhs;
        lhs_vi = self#vi_from_ispec_decl lhs;
        rhs_vi = self#vi_from_ispec_decl rhs;
      }

  method private log_resolved_constraints constraints =
    List.iter
      (fun c ->
        Options.Self.debug ~level:3
          "Resolved external call-order constraint %a < %a"
          Printer.pp_varinfo c.lhs_vi
          Printer.pp_varinfo c.rhs_vi)
      constraints

  method private create_ghost_vars file constraints =
    let lhs_decls =
      List.fold_left
        (fun acc constraint_ ->
          StringMap.add constraint_.lhs_decl.ispec_fname constraint_.lhs_decl acc)
        StringMap.empty
        constraints
    in
    StringMap.map (make_ghost_call_var file) lhs_decls

  method private log_ghost_vars vars =
    StringMap.iter
      (fun lhs_name var ->
        Options.Self.debug ~level:3
          "Generated ghost call-state variable %a for %s"
          Printer.pp_varinfo var.ghost_vi
          lhs_name)
      vars

  method private log_entry_schedule = function
    | EntrySchedule schedule ->
      Options.Self.debug ~level:3
        "Computed call-order harness schedule: %s"
        (String.concat " < " (List.map (fun d -> d.ispec_fname) schedule))
    | EntryOrderCycle cyclic ->
      self#print_error
        (Format.asprintf
          "The entry_order specification contains a cycle involving: %s"
          (String.concat ", " (List.map (fun d -> d.ispec_fname) cyclic)))

  method !vfile file =
    let spec = self#get_ispec () in
    (* This first checker slice only builds the resolved model needed by later
       steps: ghost-state generation, call-site assertions, harness generation,
       and WP result mapping. *)
    let constraints =
      List.map self#resolve_order_constraint spec.extern_calls.call_order
    in
    let schedule = entry_schedule_of_ispec spec in
    let vars = self#create_ghost_vars file constraints in
    resolved_constraints <- constraints;
    entry_schedule <- Some schedule;
    ghost_vars <- vars;
    self#log_resolved_constraints constraints;
    self#log_ghost_vars vars;
    self#log_entry_schedule schedule;
    Cil.SkipChildren
end
