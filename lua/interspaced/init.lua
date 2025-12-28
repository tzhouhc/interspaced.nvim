---@class Config
---@field opt string Your config option
---@field aggressive_spacing boolean Whether to always ensure single spaces
---@field preserve_tabs boolean Whether to preserve tab characters
---@field max_operation_size integer Maximum text size for automatic spacing
---@field timeout_ms integer Operation timeout in milliseconds
local config = {
  opt = "Hello!",
  aggressive_spacing = true,
  preserve_tabs = false,
  max_operation_size = 100 * 1024, -- 100KB
  timeout_ms = 100,
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- Load core module
M.core = require("interspaced.core")

return M
