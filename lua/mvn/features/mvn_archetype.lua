local pickers = require("mvn.view.pickers")
local job = require("mvn.utils.job")
local Config = require("mvn.core.config")
local util = require("mvn.util")
local log = require("mvn.utils.log")
local Float = require("mvn.view.float")

---@type MWinFloat
local window

local M = {}

function M:create_projects()
    self.groupId = vim.fn.input("Group ID: ", "com.chando")
    self.artifactId = vim.fn.input("Artifact Id: ", "my-app")
    self.archetypeVersion = vim.fn.input("Archettype version: ", "1.5")
    self.cwd = vim.fn.getcwd()

    local args = {
        "archetype:generate",
        "-DarchetypeArtifactId=" .. self.artifactType,
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
        float = window,
        on_exit = function(message, code)
            if code ~= 0 then
                log.error(message)
            end

            if window:buf_valid() then
                window:on("WinClosed", function()
                    vim.schedule(function()
                        util.change_location(self.cwd .. "/" .. self.artifactId)
                    end)
                end)
            end
        end
    })
end

M.choose_projects = function()
    local self = setmetatable({}, { __index = M })
    window = setmetatable({}, { __index = Float })

    pickers.pickers_menu({
        title = "Maven create project",
        results = Config.options.archetype,
        callback = function(selection)
            self.artifactType = selection[1]
            self:create_projects()
        end
    })
end

return M
