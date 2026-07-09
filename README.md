# VerNFR

VerNFR is a [Frama-C](https://frama-c.com) plugin for
verification of non-functional requirements of C code.
Currently, it supports specifying and verifying properties
related to control flow and data flow using interface
specification contracts.

## Requirements

- [Dune](https://dune.build) 3.13 or later
- [OCaml](https://ocaml.org) 4.14 or later
- [Frama-C](https://frama-c.com) 32

## Building

The easiest way to build and install VerNFR is via
[opam](https://opam.ocaml.org/doc/Install.html). The
following command installs VerNFR and its dependencies
when run from the root of the repository:

```shell
opam pin add frama-c-vernfr . --kind=path
```

To instead build and install manually when all dependencies
are available, use `dune build` and `dune install` in the root.

## Testing

Regressions testing uses the `frama-c-ptests` utility.
Use `dune test` to run all regression tests.

## Verification tasks and options

VerNFR takes a C module as input (usually a `.c` file and an `.h` file)
along with an interface contract (`.is` file) and can perform the
following verification tasks:

- T1: External function calls adheres to the `.is` file whitelist, `-nfr-check-calls`  
- T2: Absence of function pointers `-nfr-fun-ptrs`   
- T3: No function definitions (intended for use on h-file) `-nfr-no-fun-defs`  
- T4: Only h-files included  
- T5: All entry points in the is-file are declared `-nfr-all-entries-declared`  
- T6: All entry points in the is-file are defined `-nfr-all-entries-defined`  
- T7: Non-entry points are declared in the c-file with static storage specifier `-nfr-only-entries`  
- T8: Variables have static storage-specifier `-nfr-static-vars`
- T9: All memory locations are explicitly initialized or written to before they are read `-nfr-proper-init`  
- T10: Absence of pointer literals `-nfr-check-ptr-literals`  
- T11: Typedefs are always used when possible `-nfr-typedefs` 

Every task except T4 can be run directly using Frama-C with the option indicated in the list above.
For example, T1 can be run using the following command: 

```shell
frama-c -vernfr -nfr-check-calls -nfr-ispec test.is test.c
```

See `frama-c -nfr-h` for more information on how to use VerNFR with Frama-C. 

For convenience, we provide the script `./scripts/all-checks.sh` as an entry point for
VerNFR that performs all verification tasks. The script takes as input a module
consisting of a `.c` file and an `.h` file, and an interface contract `.is` file.

The script can be run as follows:

```shell
./scripts/all-checks.sh --modname <name> --folder <folder_path>
```
where the module file names are `<folder_path>/<name>.c`, `<folder_path>/<name>.h`, and `<folder_path>/<name>.is`

## Interface Specification Contracts

An Interface Specification (IS) contract declares:

 - The name of the module.  
 - The entry points, expected to be declared in the h-file and defined in the c-file.  
 - The assumed order in which the entry points will be called by other modules.  
 - The permitted external function calls per external header file.  
 - The order of external function calls, which the module should adhere to, given that the assumed order on the entry points is satisfied.  

The following is an example IS contract, more examples are available in the `tests` directory:
```c
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
