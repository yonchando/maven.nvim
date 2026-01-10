local pickers = require("mvn.pickers")
local ui = require("mvn.ui")
local mvn_command = require("mvn.mvn_command")
local mvn_archetype = require("mvn.mvn_archetype")
local spring_project = require("mvn.spring_project")
local spring_dependencies = require("mvn.spring_dependencies")

local floats = {
    bufnr = -1,
    win = -1
}

---@type Job|nil
CurrentJob = nil

---@class Opts
---@field theme table|nil
---@field cmd table|nil
---@field archetype table|nil

---@type Opts
Opts = {}

local M = {}

---@param opts Config|nil
M.setup = function(opts)
    Opts = {
        theme = require("telescope.themes").get_dropdown({}),
        cmd = {
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
        archetype = {
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
        }
    }
    if opts ~= nil then
        Opts = vim.tbl_deep_extend("force", Opts, opts)
    end
end

M.mvn_cli = function()
    pickers.pickers_menu({
        title = "Maven ClI",
        results = Opts.cmd,
        callback = function(selection)
            local cwd = vim.fn.getcwd()
            floats = ui.create_output({})

            if vim.fn.filereadable(cwd .. "/pom.xml") then
                mvn_command.run_maven(selection, floats.bufnr, cwd)
            else
                vim.api.nvim_buf_set_lines(floats.bufnr, 0, -1, false, { "pom.xml not found!" })
            end
        end
    })
end

M.mvn_create_project = function()
    pickers.pickers_menu({
        title = "Maven create project",
        results = Opts.archetype,
        callback = function(selection)
            mvn_archetype.create_projects(selection)
        end
    })
end

M.spring_initializr_project = function()
    spring_project.create_project()
end

M.spring_dependencies = function()
    spring_dependencies.choose_dependencies()
end

return M
