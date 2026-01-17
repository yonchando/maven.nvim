local config = require("mvn.core.config")
local job = require("mvn.utils.job")
local pickers = require("mvn.view.pickers")
local log = require("mvn.utils.log")

local stats = require("mvn.stats")

---@class MvnCli
---@field mvn_args string[]
---@field cwd string
local M = {}

function M:run_command()
    job.run({
        args = self.mvn_args,
        cwd = self.cwd,
        message_start = "> mvn " .. table.concat(self.mvn_args, " ") .. " ",
        message_finish = "> mvn " .. table.concat(self.mvn_args, " ") .. " ",
    })
end

M.choose_cli = function()
    local self = setmetatable({}, { __index = M })
    self.cwd = vim.fn.getcwd()

    local pom = vim.uv.fs_stat(self.cwd .. "/pom.xml")

    if pom == nil then
        log.warn("pom.xml not found!")
        return
    end

    pickers.pickers_menu({
        title = "Maven ClI",
        results = config.options.mvn_args,
        callback = function(selection)
            self.mvn_args = selection
            self:run_command()
        end
    })
end

M.run_last = function()
    local self = setmetatable({}, { __index = M })

    if #self.mvn_args then
        self:run_command()
    else
        log.warn("No recently command mvn run!")
    end
end

return M
