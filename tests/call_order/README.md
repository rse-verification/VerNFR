# Call-order examples

These examples cover the `entry_order` and `external_call_order` syntax used by
interface specifications. The suite also contains the older
`simple_call_order` case, merged here so `tests/call_order` is the single ptests
suite for call-order behavior.

- `call_order_ok.c` follows the specified external call order.
- `call_order_bad1.c` follows the specified external call order.
- `call_order_bad2.c` intentionally calls `calibrate` before `configure`.
- `simple_call_order_bad.c` intentionally calls `bar` before `foo`, using the
  separate `simple_call_order.is` spec from the original external-call-order
  test.

Useful command:

```sh
frama-c -vernfr -nfr-ispec call_order.is -nfr-check-calls \
  -nfr-external-call-order -keep-unused-functions all -keep-unused-types \
  call_order_ok.c
```

Note: the checker for `external_call_order` is now wired in, but this first
slice only resolves the specification constraints and computes the entrypoint
schedule. Ghost instrumentation, harness generation, WP execution, and
constraint-specific diagnostics are still to be implemented.
