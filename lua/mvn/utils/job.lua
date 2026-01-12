local Job = require("plenary.job")
local log = require("mvn.utils.log")
local stats = require("mvn.stats")

local M = {}

local current_job

---@class RunConfig
---@field cmd string|nil
---@field args table
---@field cwd string
---@field message_finish string
---@field message_start string
---@field on_stdout function|nil
---@field on_stderr function|nil
---@field on_exit function|nil

---@class Window
---@field bufnr number
---@field win number

---@param opts RunConfig
M.run = function(opts)
    local command = opts.cmd or 'mvn'

    ---@type MWinFloat
    local float = stats.float

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
        end,

        on_exit = function()
            vim.schedule(function()
                float:stop_spinner()
                if float:buf_valid() then
                    vim.api.nvim_buf_set_lines(float.bufnr, 0, 1, false, { opts.message_finish .. " ✔" })
                    vim.bo[float.bufnr].modifiable = false
                end
                current_job = nil

                if opts.on_exit ~= nil then
                    opts.on_exit()
                end
            end)
        end,
    })

    -- clear previous output
    if float:buf_valid() then
        vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, { opts.message_start .. "..." })
    end

    float:start_spinner(opts.message_start)

    float:on("WinClosed", function(self)
        if current_job then
            current_job:shutdown()
            self:stop_spinner()
        end
    end)
    float:on({ "BufDelete", "BufHidden" }, float.close)

    current_job:start()
end

return M
