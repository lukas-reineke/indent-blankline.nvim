local hooks = require "ibl.hooks"

hooks.register(hooks.type.SKIP_LINE, hooks.builtin.skip_preproc_lines, { bufnr = 0 })
