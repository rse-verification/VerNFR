open Cil_types
open Parser_lib.Ispec
open Options

let vi_is_static vi = match vi.vstorage with | Static -> true | _ -> false

let typ_of_base_type = function
  | Void -> Cil_const.voidType
  | Bool -> Cil_const.boolType
  | Char -> Cil_const.charType
  | Short -> Cil_const.shortType
  | Int -> Cil_const.intType
  | Long -> Cil_const.longType
  | LongLong -> Cil_const.longLongType
  | Float -> Cil_const.floatType
  | Double -> Cil_const.doubleType
  (* | Unsigned None -> { tnode = TInt IUInt; tattr = [] }
  | Unsigned (Some b) ->
      let t = typ_of_base_type b in
      begin match t.tnode with
      | TInt ik -> { t with tnode = TInt (unsigned_ikind ik) }
      | _ -> t
      end *)
  (* | Signed None -> { tnode = TInt IInt; tattr = [] }
  | Signed (Some b) ->
      let t = typ_of_base_type b in
      begin match t.tnode with
      | TInt ik -> { t with tnode = TInt (signed_ikind ik) }
      | _ -> t
      end *)
  (* | Struct name ->
      (* Lookup or create a compinfo for this struct *)
      let ci = Cil_const.mkCompInfo ~cstruct:true name [] in
      { tnode = TComp ci; tattr = [] } *)
  (* | Custom name ->
      (* Lookup a typedef typeinfo by name, or create a placeholder *)
      let ti = Cil_const.mkTypeInfo name (typ_of_base_type Int) in
      { tnode = TNamed ti; tattr = [] } *)
  | _ -> Kernel.fatal "not yet implemented"

let rec typ_of_ispec_type t =
  match t with
  | Base b -> typ_of_base_type b
  | Ptr inner ->
      let inner_typ = typ_of_ispec_type inner in
      { tnode = TPtr inner_typ; tattr = [] }
  | Const inner ->
      let inner_typ = typ_of_ispec_type inner in
      { inner_typ with tattr = ("const", []) :: inner_typ.tattr } 


(* gets corresponding vi in the file f**)
let ispec_decl_to_cil_type isd = 
  let ret_type = typ_of_ispec_type isd.ispec_ret_type in
  let param_tuples = 
    List.map 
      (fun is_par -> 
        let par_name = match is_par.ispec_pname with
          | Some(s) -> s
          | None -> Kernel.fatal "function par i ispec with no name"
        in
        let par_type = typ_of_ispec_type is_par.ispec_ptype in
        (par_name, par_type, [])
      )
      isd.ispec_params
  in
  let ftype = Cil_const.mk_tfun ret_type (Some param_tuples) false in
  ftype
  (* Cil.findOrCreateFunc f isd.ispec_fname ftype *)
    (* | None -> Cil.makeGlobalVar isd.ispec_fname ftype  *)

let viEq vi1 vi2 = (Cil.areCompatibleTypes vi1.vtype vi2.vtype) && vi1.vname = vi2.vname
let viInList vi = List.exists (fun vi' -> viEq vi vi')

let unroll_call_exp e = 
  match e.enode with 
    | Lval((lh, _)) -> Some(lh)
    | _ -> 
        Self.debug ~level:3 "not an lval in a call exp: %a" Printer.pp_exp e;
        None


let vi_to_kf_opt vi = 
  try 
    Some(Globals.Functions.get vi)
  with Not_found ->
    None

module ISDSet = Set.Make(IspecDeclOrd)
(* module VISet: Set.S with type elt = Cil_types.varinfo ;; *)
module VISet = Cil_datatype.Varinfo.Hptset
(* Gets predecessors wrp to call entry partial order **)
let get_fns_called_before isd ispec = 
  Self.debug ~level:5 "gettingn predecessors for %s" (Parser_lib.Ispec.string_of_ispec_decl isd);
  Self.debug ~level:5 "ispec: %s" (Parser_lib.Ispec.string_of_ispec ispec);

  let rec isd_bfs ocs q res = 
    match q with 
      | [] -> 
        res
      | h::t -> 
        let new_pred_fns = 
          List.filter_map (fun oc ->
          Self.debug ~level:5 "A: %s  B: %s" (Parser_lib.Ispec.string_of_order_constraint oc) (h.ispec_fname); 
            match oc with 
              | CalledBefore (fn', {ispec_fname = name; _}) 
                when name = h.ispec_fname -> Some(fn')
              | _ -> 
                None
          ) ispec.entry_order
        in
        let res' = ISDSet.union (ISDSet.of_list new_pred_fns) res in 
        (* let res' = List.fold_left (fun acc isd -> ISDSet.add isd acc) res new_pred_fns in *)
        let q' = t @ new_pred_fns in
        isd_bfs ocs q' res'
  in
  let res = isd_bfs ispec.entry_order [isd] ISDSet.empty in
  ISDSet.iter (fun x -> Self.debug ~level:5 "Result: %s" (Parser_lib.Ispec.string_of_ispec_decl x)) res;  
  res