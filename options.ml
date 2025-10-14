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
