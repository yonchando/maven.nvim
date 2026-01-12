local log = require("mvn.utils.log")

---@class MCoreConfig
local M = {}

---@class MConfig
M.defaults = {
    mvn_args        = {
        "clean",
        "compile",
        "package",
        "verify",
        "validate",
        "test",
        "site",
        "deploy",
        "install",
        "exec:java",
        "spring-boot:run"
    },
    archetype       = {
        "maven-archetype-simple",
        "maven-archetype-quickstart",
        "maven-archetype-webapp",
        "maven-archetype-portlet",
        "maven-archetype-plugin",
        "maven-archetype-plugin-site",
        "maven-archetype-site",
        "maven-archetype-site-simple",
        "maven-archetype-site-skin",
        "maven-archetype-j2ee-simple",
    },
    telescope_theme = require("telescope.themes").get_dropdown({}),
    ui              = {
        size = { width = 0.8, height = 0.8 },
        border = "rounded",
    }
}

M.options = {}

M.ns = vim.api.nvim_create_namespace("maven.nvim")

---@param opts? PluginConfig
M.setup = function(opts)
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
