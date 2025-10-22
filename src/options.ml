let help_msg = "Plugin for varifying non-functional requirements"

module Self = Plugin.Register
  (struct
    let name = "vernfr"
    let shortname = "nfr"
    let help = help_msg
  end)

module Enabled = Self.False
(struct
  let option_name = "-vernfr"
  let help = "when on (off by default), " ^ help_msg
end)


module CheckStatic = Self.False
(struct
  let option_name = "-nfr-static-vars"
  let help = "when on (off by default), emits a warning if a global variable does not have static storage" 
end)

module CheckEntry = Self.False
(struct
  let option_name = "-nfr-entry-check"
  let help = "when on (off by default), emits a warning if function is declared that is not in the \
    list of entry-point functions in the specification. This option SHOULD ALWAYS be used in combination with the \
    frama-c kernel option '-keep-unused-functions all'" 
end)

module CheckCalls = Self.False
(struct
  let option_name = "-nfr-check-calls"
  let help = "when on (off by default), emits a warning if any external function \
    call is to a function not in the whitelist in the specification \
    (does not emit warnings for calls to local functions (with static storage))" 
end)

module CheckFunPtrs = Self.False
(struct
  let option_name = "-nfr-fun-ptrs"
  let help = "when on (off by default), emits a warning if any function call is a call \
    to a function pointer. Verification is at call sites." 
end)

module CheckAll = Self.False
(struct
  let option_name = "-nfr-all"
  let help = "when on (off by default), runs all nfr checks by vernfr" 
end)