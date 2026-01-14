local pickers = require("mvn.view.pickers")
local job = require("mvn.utils.job")
local stats = require("mvn.stats")
local Config = require("mvn.core.config")
local util = require("mvn.util")
local log = require("mvn.utils.log")

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

    job.run({
        cwd = self.cwd,
        args = args,
        message_start = "Proejct initial",
        message_finish = "Project initial success",
        on_exit = function()
            if stats.float:buf_valid() then
                stats.float:on("WinClosed", function()
                    vim.schedule(function()
                        util.change_location(self.cwd .. "/" .. self.artifactId)
                    end)
                end)
            end
        end
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
