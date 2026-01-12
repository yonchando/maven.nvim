local config = require("mvn.core.config")
local job = require("mvn.utils.job")
local pickers = require("mvn.view.pickers")
local Float = require("mvn.view.float")
local log = require("mvn.utils.log")

local stats = require("mvn.stats")

local M = {}

M.choose_cli = function()
    pickers.pickers_menu({
        title = "Maven ClI",
        results = config.options.mvn_args,
        callback = function(selection)
            local cwd = vim.fn.getcwd()

            stats.float = setmetatable({}, { __index = Float })
            stats.float:init()

            local pom = vim.uv.fs_stat(cwd .. "/pom.xml")

            if pom ~= nil then
                local mvn_args = selection
                job.run({
                    args = mvn_args,
                    cwd = cwd,
                    message_start = "> mvn " .. table.concat(mvn_args, " ") .. " ",
                    message_finish = "> mvn " .. table.concat(mvn_args, " ") .. " ",
                })
            else
                if stats.float:buf_valid() then
                    vim.api.nvim_buf_set_lines(stats.float.bufnr, 0, -1, false, { "pom.xml not found!" })
                end
            end
        end
    })
end

return M
