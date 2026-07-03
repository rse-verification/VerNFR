Verification of Non-Functional Requirements (VerNFR).
Compatible with Frama-C version 32.0

## Testing
Regressions testing using frama-c-ptests utility. run `dune build @runtest`

## Building
To build, run `dune build @install` and `dune install` from root folder

## Verification
The main entry point to VerNFR is the script `./scripts/all-checks.sh`, which takes as input a module consisting of a c-file and an h-file, and an interface contract (is-file), and performs the following verification tasks.

T1: External function calls adheres to the is-file whitelist `-nfr-check-calls`  
T2: Absence of function pointers `-nfr-fun-ptrs`   
T3: No function definitions (intended for use on h-file) `-nfr-no-fun-defs`  
T4: Only h-files included  
T5: All entry points in the is-file are declared `-nfr-all-entries-declared`  
T6: All entry points in the is-file are defined `-nfr-all-entries-defined`  
T7: Non-entry points are declared in the c-file with static storage specifier `-nfr-only-entries`  
T8: Variables have static storage-specifier `-nfr-static-vars`
T9: All memory locations are explicitly initialized or written to before they are read `-nfr-proper-init`  
T10: Absence of pointer literals `-nfr-check-ptr-literals`  
T11: Typedefs are always used when possible `-nfr-typedefs`  

To run the script: `./scripts/all-checks.sh --modname <name> --folder <folder_path>`  
where the module file names are `<folder_path>/<name>.c`, `<folder_path>/<name>.h`, and `<folder_path>/<name>.is`

Each task (except T4) can also be run directly in Frama-C, for example, T1 can be run using `frama-c -vernfr -nfr-check-calls -nfr-ispec test.is test.c`   
See `frama-c -nfr-h` for more information on how to use VerNFR with Frama-C.

## Syntax IS-file 
The IS-files declare:   
 - The name of the module.  
 - The entry points, expected to be declared in the h-file and defined in the c-file.  
 - The assumed order in which the entry points will be called by other modules.  
 - The permitted external function calls per external header file.  
 - The order of external function calls, which the module should adhere to, given that the assumed order on the entry points is satisfied.  

The following shows an example of the syntax, more examples are available in `tests`  
```
module tmon {
  entry_functions: { void tmon_init(void), int tmon_step(void) }
  entry_order: { tmon_init < tmon_step }
  external_calls: {
    sensors.h: { void tmon_sens_create(void), int tmon_sens_read(void) },
    warnings.h: { void tmon_warn_create(void), void tmon_warn_write(int) },
    utils.h: { int update_sat(int, int, int, int) }
  }
  external_call_order: { 
    tmon_sens_create < tmon_sens_read, tmon_warn_create < tmon_warn_write
  }
}
```
