(* ispec.ml *)

(* -------------------------------------------------------------------------- *)
(* Abstract Syntax Tree for Interface Specifications                          *)
(* -------------------------------------------------------------------------- *)

type base_type =
  | Void
  | Bool
  | Char
  | Short
  | Int
  | Long
  | LongLong
  | Float
  | Double
  | Unsigned of base_type option    (* e.g. unsigned, unsigned int *)
  | Signed of base_type option      (* e.g. signed, signed char *)
  | Struct of string
  | Custom of string                (* user-defined type *)

type ispec_type =
  | Base of base_type
  | Ptr of ispec_type
  | Const of ispec_type

type ispec_param = {
  ispec_ptype : ispec_type;
  ispec_pname : string option;
}

type ispec_decl = {
  ispec_ret_type : ispec_type;
  ispec_fname : string;
  ispec_params : ispec_param list;
}

type include_item = {
  hfile : string;
  fns : ispec_decl list;
}

type order_constraint =
  | CalledBefore of ispec_decl * ispec_decl

type extern_calls = {
  includes : include_item list;
  call_order : order_constraint list;
}

type ispec = {
  entry_fns : ispec_decl list;
  entry_order : order_constraint list;
  extern_calls : extern_calls;
}

(* -------------------------------------------------------------------------- *)
(* Pretty-printers (optional, for debugging)                                  *)
(* -------------------------------------------------------------------------- *)

let rec string_of_base_type = function
  | Void -> "void"
  | Bool -> "bool"
  | Char -> "char"
  | Short -> "short"
  | Int -> "int"
  | Long -> "long"
  | LongLong -> "long long"
  | Float -> "float"
  | Double -> "double"
  | Unsigned None -> "unsigned"
  | Unsigned (Some t) -> "unsigned " ^ string_of_base_type t
  | Signed None -> "signed"
  | Signed (Some t) -> "signed " ^ string_of_base_type t
  | Struct s -> "struct " ^ s
  | Custom s -> s

let rec string_of_ispec_type = function
  | Base b -> string_of_base_type b
  | Ptr t -> (string_of_ispec_type t) ^ "*"
  | Const t -> "const " ^ string_of_ispec_type t

let string_of_ispec_param p =
  match p.ispec_pname with
  | Some n -> string_of_ispec_type p.ispec_ptype ^ " " ^ n
  | None -> string_of_ispec_type p.ispec_ptype

let string_of_ispec_decl d =
  Printf.sprintf "%s %s(%s)"
    (string_of_ispec_type d.ispec_ret_type)
    d.ispec_fname
    (String.concat ", " (List.map string_of_ispec_param d.ispec_params))
