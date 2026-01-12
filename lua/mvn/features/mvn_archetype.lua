local pickers = require("mvn.view.pickers")
local Float = require("mvn.view.float")
local job = require("mvn.utils.job")
local stats = require("mvn.stats")
local Config = require("mvn.core.config")
local util = require("mvn.util")

local M = {}

M.create_projects = function(self, selection)
    self.groupId = vim.fn.input("Group ID: ", "com.chando")
    self.artifactId = vim.fn.input("Artifact Id: ", "my-app")
    self.archetypeVersion = vim.fn.input("Archettype version: ", "1.5")
    self.cwd = vim.fn.getcwd()

    local args = {
        "archetype:generate",
        "-DarchetypeArtifactId=" .. selection[1],
        "-DgroupId=" .. self.groupId,
        "-DartifactId=" .. self.artifactId,
        "-DarchetypeVersion=" .. self.archetypeVersion,
        "-DinteractiveMode=false"
    }

    stats.float = setmetatable({}, { __index = Float })
    stats.float:init()

    stats.float:on("WinClosed", function()
        vim.schedule(function()
            util.change_location(self.cwd .. "/" .. self.artifactId)
        end)
    end)

    if stats.float:buf_valid() then
        vim.api.nvim_buf_set_lines(stats.float.bufnr, 1, 1, false, args)
    end

    job.run({
        cwd = self.cwd,
        args = args,
        message_start = "Proejct initial",
        message_finish = "Project initial success",
    })
end

M.choose_projects = function()
    pickers.pickers_menu({
        title = "Maven create project",
        results = Config.options.archetype,
        callback = function(selection)
            M:create_projects(selection)
        end
    })
end

return M
