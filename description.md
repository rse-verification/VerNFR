This file describes the syntax for the interface specification files (.is). For examples, see ./tests or ./case_studies

An interface specification defines the interface for a C module, where a C module consists of a c-file and an h-file. The interface specification has the following syntax.

Module m1 {
  entry_functions: { 
    <Function-List>
  }
  entry_order: { <Order-List> }
  external_calls: { <Function-Include-List> }
  external_call_order: { <Order-List> }
}

Where the fields are as follows:

## entry_functions
The entry functions that should be implemented by the module and can be called by external modules, these should be declared in the h-file and defined in the c-file. A <function-list> is a comma-separated list of function declarations following C syntax. 

## entry_order
This describes an order in which the entry function are assumed to be called. For example if "foo" and "bar" are in the list of entry functions, then "foo < bar" means that foo has to be called before bar is called. Note that this is an assumption made by the module being specified, which has to be satisfied by any external module using the module.

## External Calls
This is a whitelist of functions from external modules that the module is allowed to call. Each function may also be prefixed by an ACSL function contract (this is however not yet implemented in the parser of interface specifications).
The list is defined per external h-file, e.g., as follows:
ext_mod: { void ext_foo(int x), int ext_bar(void) }

## external_call_order
Defines a call order on outgoing calls to external modules. Note that this is a requirement to be satisfied by the module being specified. See entry_order for syntax.

