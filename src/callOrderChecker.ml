open Cil_types
open GenericNFRChecker
open Parser_lib.Ispec

module StringMap = Map.Make(String)

let call_order_emitter =
  Emitter.create
    "vernfr_call_order"
    [Emitter.Code_annot; Emitter.Funspec]
    ~correctness:[]
    ~tuning:[]

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

(* Map each entry function name to its position in entry_fns, so the stable
   topological sort can keep the user-written order for unrelated entries. *)
let make_entry_positions entries =
  entries
  |> List.mapi (fun idx decl -> decl_name decl, idx)
  |> List.fold_left
    (fun acc (name, idx) -> StringMap.add name idx acc)
    StringMap.empty

(* Build the partial-order graph from entry_order assumptions. If the graph is
   cyclic, report the cyclic entries; otherwise return a stable topological
   schedule that will later drive the generated harness. *)
let entry_schedule_of_ispec spec =
  let entries = spec.entry_fns in
  let entry_positions = make_entry_positions entries in
  let entry_position decl =
    StringMap.find (decl_name decl) entry_positions
  in
  (* Vertices are the entry declarations themselves. Equality/hash use the
     entry function name, while comparison follows the user's entry_fns order so
     ocamlgraph's stable topological sort keeps unrelated entries deterministic
     without making the harness order alphabetical. *)
  let module EntryVertex = struct
    type t = ispec_decl

    let compare d1 d2 =
      if String.equal (decl_name d1) (decl_name d2) then 0
      else Int.compare (entry_position d1) (entry_position d2)

    let equal d1 d2 =
      String.equal (decl_name d1) (decl_name d2)

    let hash decl =
      Hashtbl.hash (decl_name decl)
  end in
  let module EntryGraph =
    Graph.Persistent.Digraph.ConcreteBidirectional(EntryVertex)
  in
  let module EntryTopological = Graph.Topological.Make_stable(EntryGraph) in
  let module EntryComponents = Graph.Components.Make(EntryGraph) in
  let graph =
    List.fold_left
      EntryGraph.add_vertex
      EntryGraph.empty
      entries
  in
  let graph =
    List.fold_left
      (fun graph -> function
        | CalledBefore (lhs, rhs) ->
          EntryGraph.add_edge graph lhs rhs)
      graph
      spec.entry_order
  in
  (* In a directed graph, cycles are exactly strongly connected components with
     at least two vertices, plus singleton components that have a self-loop. *)
  let is_cyclic_component = function
    | [] -> false
    | [v] -> EntryGraph.mem_edge graph v v
    | _ :: _ :: _ -> true
  in
  let cyclic_vertices =
    EntryComponents.scc_list graph
    |> List.filter is_cyclic_component
    |> List.concat
    |> List.sort_uniq EntryVertex.compare
  in
  if cyclic_vertices <> [] then
    let cyclic =
      List.filter
        (fun decl -> List.exists (EntryVertex.equal decl) cyclic_vertices)
        entries
    in
    EntryOrderCycle cyclic
  else
    let schedule =
      EntryTopological.fold
        (fun decl acc -> decl :: acc)
        graph
        []
      |> List.rev
    in
    EntrySchedule schedule

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

(* Keep call-site matching deliberately simple: only direct calls to named
   functions are relevant for these first-order call-order constraints. CIL
   uses Local_init for declarations initialized by a function call, e.g.
   "int value = sample();", so handle that form alongside plain Call. *)
let direct_call_varinfo = function
  | { skind = Instr (Call (_, Var vi, _, loc)); _ } -> Some (vi, loc)
  | { skind = Instr (Local_init (_, ConsInit (vi, _, _), loc)); _ } ->
    Some (vi, loc)
  | _ -> None

let ghost_assignment_stmt ~loc ghost_vi =
  Cil.mkStmtOneInstr
    ~ghost:true
    (Set ((Var ghost_vi, NoOffset), Cil.one ~loc, loc))

let assertion_name lhs rhs =
  "nfr_call_order_" ^ lhs.ispec_fname ^ "_before_" ^ rhs.ispec_fname

let preservation_behavior_name =
  "nfr_call_order_preserves_ghosts"

let ghost_var_called_predicate ~loc lhs rhs ghost_vi =
  let ghost_term = Cil.cvar_to_term ~loc ghost_vi in
  let one = Logic_const.tinteger ~loc 1 in
  Logic_const.prel
    ~loc
    ~names:[assertion_name lhs rhs]
    (Req, ghost_term, one)

(* External callees are specified only by declarations in the module under
   verification. To reason across such calls, WP needs a frame condition for
   the generated ghost flags: unless VernFR itself sets a flag after an lhs
   call, ordinary calls must preserve the whole generated call-order state. *)
let ghost_var_preserved_predicate ~loc ghost_vi =
  let current = Cil.cvar_to_term ~loc ghost_vi in
  let old = Logic_const.told ~loc current in
  Logic_const.prel
    ~loc
    ~names:["nfr_preserve_" ^ ghost_vi.vname]
    (Req, current, old)

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
          "Generated ghost call variable %a for %s"
          Printer.pp_varinfo var.ghost_vi
          lhs_name)
      vars

  method private add_preservation_contracts constraints vars =
    (* Add one generated behavior to every function that appears on either side
       of a call-order constraint. The behavior says that all generated ghost
       flags are unchanged by the call. This is intentionally conservative:
       even lhs functions preserve the flags during the call itself; the
       instrumentation marks the lhs as seen in a separate ghost assignment
       immediately after the call site. *)
    let ghost_vis =
      StringMap.bindings vars |> List.map (fun (_, var) -> var.ghost_vi)
    in
    (* De-duplicate callees by current C name, since a function may appear in
       several constraints. *)
    let add_callee acc constraint_ =
      acc
      |> StringMap.add constraint_.lhs_vi.vname constraint_.lhs_vi
      |> StringMap.add constraint_.rhs_vi.vname constraint_.rhs_vi
    in
    let callees = List.fold_left add_callee StringMap.empty constraints in
    let add_contract _callee_name callee_vi =
      try
        let kf = Globals.Functions.get callee_vi in
        let loc = callee_vi.vdecl in
        let post_cond =
          List.map
            (fun ghost_vi ->
              Normal,
              Logic_const.new_predicate
                (ghost_var_preserved_predicate ~loc ghost_vi))
            ghost_vis
        in
        let behavior =
          Cil.mk_behavior
            ~name:preservation_behavior_name
            ~post_cond
            ()
        in
        (* Register through Annotations rather than mutating the funspec only:
           this keeps Frama-C's annotation/property tables consistent, and also
           makes the generated contract show up in the proof-project printer. *)
        Annotations.add_behaviors call_order_emitter kf [behavior]
      with Not_found ->
        Options.Self.debug ~level:3
          "Skipping ghost-preservation contract for unregistered callee %a"
          Printer.pp_varinfo callee_vi
    in
    if ghost_vis <> [] then
      StringMap.iter add_contract callees

  method private ghost_var_for_lhs lhs_decl =
    Option.map
      (fun var -> var.ghost_vi)
      (StringMap.find_opt lhs_decl.ispec_fname ghost_vars)

  method private constraints_with_rhs callee_vi =
    List.filter
      (fun constraint_ -> Utils.viEq callee_vi constraint_.rhs_vi)
      resolved_constraints

  method private ghost_var_for_lhs_call callee_vi =
    List.find_map
      (fun constraint_ ->
        if Utils.viEq callee_vi constraint_.lhs_vi then
          self#ghost_var_for_lhs constraint_.lhs_decl
        else None)
      resolved_constraints

  method private add_call_order_assertions stmt callee_vi loc =
    if not (Annotations.has_code_annot ~emitter:call_order_emitter stmt) then
      List.iter
        (fun constraint_ ->
          match self#ghost_var_for_lhs constraint_.lhs_decl with
          | None -> ()
          | Some ghost_vi ->
            let pred =
              ghost_var_called_predicate
                ~loc
                constraint_.lhs_decl
                constraint_.rhs_decl
                ghost_vi
            in
            let annot =
              Logic_const.new_code_annotation
                (AAssert ([], Logic_const.toplevel_predicate pred))
            in
            match self#current_kf with
            | Some kf ->
              Annotations.add_code_annot call_order_emitter ~kf stmt annot
            | None ->
              Annotations.add_code_annot call_order_emitter stmt annot)
        (self#constraints_with_rhs callee_vi)

  method private is_generated_ghost_assignment_to ghost_vi stmt =
    match stmt.skind with
    | Instr (Set ((Var vi, NoOffset), _, _)) ->
      stmt.ghost && Cil_datatype.Varinfo.equal vi ghost_vi
    | _ -> false

  method private instrument_stmt stmt =
    match direct_call_varinfo stmt with
    | None -> None
    | Some (callee_vi, loc) ->
      self#add_call_order_assertions stmt callee_vi loc;
      Option.map
        (fun ghost_vi -> ghost_vi, ghost_assignment_stmt ~loc ghost_vi)
        (self#ghost_var_for_lhs_call callee_vi)

  method private instrument_block_stmts stmts =
    (* Assertions are attached to the call statement itself, which Frama-C
       prints immediately before the statement. The lhs marker is a ghost
       statement inserted after the call, with a small idempotence check for
       repeated runs through -then. *)
    let rec aux acc = function
      | [] -> List.rev acc
      | stmt :: rest ->
        match self#instrument_stmt stmt, rest with
        | Some (ghost_vi, _), next :: rest'
          when self#is_generated_ghost_assignment_to ghost_vi next ->
          aux (stmt :: acc) (next :: rest')
        | Some (_, ghost_stmt), _ ->
          aux (ghost_stmt :: stmt :: acc) rest
        | None, _ ->
          aux (stmt :: acc) rest
    in
    aux [] stmts

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

  method private run_in_current_project () =
    (* This method assumes Project.current () is already the private call-order
       proof project. Inside that sandbox the checker can use the same in-place
       visitor style as the rest of VernFR without polluting the user's main
       Frama-C project. *)
    Options.Self.feedback "Running %s" self#name;
    resolved_constraints <- [];
    entry_schedule <- None;
    ghost_vars <- StringMap.empty;
    cil_file <- Some (Ast.get ());
    if Option.is_some ispec then begin
      self#make_entry_vis ();
      self#make_callable_vis ()
    end;
    Visitor.visitFramacFileSameGlobals
      (self :> Visitor.frama_c_inplace)
      (self#get_cil_file ())

  method private print_generated_code () =
    Printer.pp_file Format.std_formatter (Ast.get ());
    Format.pp_print_flush Format.std_formatter ()

  method! run () =
    (* The call-order checker generates proof scaffolding: ghost globals,
       assertions, and eventually a harness. Keep that scaffolding in a copied
       project so the user's main project remains available for the rest of the
       VernFR checks and any later Frama-C analyses. *)
    (* Frama-C project copies reset projectified parameters to their defaults.
       Capture the option while still in the user's project, then use the
       captured value after switching to the proof project. *)
    let print_generated_code = Options.PrintCallOrder.get () in
    let proof_prj =
      File.create_project_from_visitor
        ~last:false
        "vernfr_call_order_proof"
        (fun prj -> new Visitor.frama_c_copy prj)
    in
    Project.on proof_prj
      (fun () ->
        self#run_in_current_project ();
        if print_generated_code then
          self#print_generated_code ())
      ()

  method !vfile file =
    let spec = self#get_ispec () in
    (* Build the resolved model once, then continue visiting function bodies so
       block-level instrumentation can insert assertions and ghost assignments. *)
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
    self#add_preservation_contracts constraints vars;
    self#log_entry_schedule schedule;
    Cil.DoChildren

  method !vblock _block =
    Cil.DoChildrenPost
      (fun block ->
        let original_stmts = block.bstmts in
        block.bstmts <- self#instrument_block_stmts block.bstmts;
        if List.length original_stmts <> List.length block.bstmts then
          Ast.mark_as_changed ();
        block)
end
