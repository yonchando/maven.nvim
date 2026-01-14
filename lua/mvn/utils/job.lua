local Job = require("plenary.job")
local log = require("mvn.utils.log")
local stats = require("mvn.stats")
local Float = require("mvn.view.float")

local M = {}

local message = {}

local current_job

---@class RunConfig
---@field cmd string|nil
---@field args table
---@field cwd string
---@field message_finish? string
---@field message_start? string
---@field on_stdout? fun(data: string)
---@field on_stderr? fun(data: string)
---@field on_exit? fun(messages: table<string>, code: number, signal: number)
---@field silent? boolean

---@class Window
---@field bufnr number
---@field win number

---@param opts RunConfig
M.run = function(opts)
    stats.float = setmetatable({}, { __index = Float })
    local float = stats.float

    if not opts.silent then
        stats.float:init()
        vim.api.nvim_set_option_value("wrap", true, {
            scope = 'local',
            win = float.win
        })
    end

    local command = opts.cmd or 'mvn'

    current_job = Job:new({
        command = command,
        args = opts.args,
        cwd = opts.cwd,
        stdout_buffered = false,
        stderr_buffered = false,

        on_stdout = function(_, data)
            if not data or data == "" then
                return
            end

            vim.schedule(function()
                if opts.on_stdout == nil then
                    if float:buf_valid() then
                        vim.api.nvim_buf_set_lines(float.bufnr, -1, -1, false, { data })
                    end
                else
                    opts.on_stdout(data)
                end

                vim.cmd("normal! G")
            end)
        end,

        on_stderr = function(_, data)
            if not data or data == "" then
                return
            end

            vim.schedule(function()
                if opts.on_stderr == nil then
                    if float:buf_valid() then
                        vim.api.nvim_buf_set_lines(float.bufnr, -1, -1, false, { "[ERROR] " .. data })
                    end
                else
                    opts.on_stderr(data)
                end
            end)

            table.insert(message, data)
        end,

        on_exit = function(_, code, signal)
            vim.schedule(function()
                if float:buf_valid() then
                    float:stop_spinner()
                    vim.api.nvim_buf_set_lines(float.bufnr, 0, 1, false, { opts.message_finish .. " ✔" })
                end

                current_job = nil

                if opts.on_exit ~= nil then
                    opts.on_exit(message, code, signal)
                end
            end)
        end,
    })

    -- clear previous output
    if float:buf_valid() then
        vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, { opts.message_start .. "..." })

        float:start_spinner(opts.message_start)

        float:on("WinClosed", function(self)
            if current_job then
                current_job:shutdown()
                self:stop_spinner()
            end
        end)
        float:on({ "BufDelete", "BufHidden" }, float.close)
    end

    current_job:start()
end

return M
