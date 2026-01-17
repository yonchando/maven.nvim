local config = require("mvn.core.config")
local log = require("mvn.utils.log")

local mvn_cli = require("mvn.features.mvn_cli")
local mvn_artchetype = require("mvn.features.mvn_archetype")
local spring_project = require("mvn.features.spring_project")
local spring_dependencies = require("mvn.features.spring_dependencies")

---@class MavenNvim
local M = {}

---@param opts? PluginConfig
M.setup = function(opts)
    config.setup(opts)
end

M.mvn_cli = function()
    mvn_cli.choose_cli()
end

M.mvn_create_project = function()
    mvn_artchetype.choose_projects()
end

M.spring_initializr_project = function()
    spring_project.initialzr()
end

M.spring_dependencies = function()
    spring_dependencies.choose_dependencies()
end

M.test = function()
    mvn_artchetype.choose_projects()
end

return M
