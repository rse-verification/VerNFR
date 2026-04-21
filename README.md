# vernfr
Verification of Non-Functional Requirements (NFR)

## Testing
Regressions testing using frama-c-ptests utility. run `dune build @tests`

## Building
to build run `dune build @install` and `dune install` from root folder

## Verification
VerNFR takes as input a module consisting of a c-file and an h-file, and an interface contract (is-file).
The script scripts/all-checks.sh runs the following tasks:

T1: External function calls adheres to the is-file whitelist.  
T2: Absence of function pointers.  
T3: No function definitions in h-file.  
T4: Only h-files are included.      
T5: All entry points in the is-file are declared.    
T6: All entry points in the is-file are defined.     
T7: Non-entry points are declared in the c-file with static storage specifier
T8: Variables have static storage-specifier.  
T9: All memory locations are explicitly initialized or written to before they are read.    
T10: Absence of pointer literals.    
T11: Typedefs are always used when possible.  

To run the script: `./scripts/all-checks.sh --modname <name> --folder <folder_path>`  
where the module file names are `<folder_path>/<name>.c`, `<folder_path>/<name>.h`, and `<folder_path>/<name>.is`


Each task can also be run directly in Frama-C, see `frama-c -nfr-h` for guidance.


## Syntax IS-file 
The is-file the following syntax. See also examples in `tests`

InterfaceContract ::= "module" id entry_points entry_order external_calls external_order  
                      
entry_points ::= "entry_functions" FunDecl*  
entry_order  ::= "entry_order" OrderConstraint*  
external_calls ::= "external_calls" extmodule*  
extmodule      ::= id FunDecl*  
external_order ::= "external_order" OrderConstraint*  
OrderConstraint ::= LT(id, id) | GT(id, id)  
