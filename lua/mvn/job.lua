local Job = require("plenary.job")
local ui = require("mvn.ui")

local M = {}

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

---@param floats Window
---@param opts RunConfig
M.run = function(floats, opts)
    local command = opts.cmd or 'mvn'

    CurrentJob = Job:new({
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
                if opts.stdout == nil then
                    if vim.api.nvim_buf_is_valid(floats.bufnr) then
                        vim.api.nvim_buf_set_lines(floats.bufnr, -1, -1, false, { data })
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
                    if vim.api.nvim_buf_is_valid(floats.bufnr) then
                        vim.api.nvim_buf_set_lines(floats.bufnr, -1, -1, false, { "[ERROR] " .. data })
                    end
                else
                    opts.on_stderr(data)
                end
            end)
        end,

        on_exit = function()
            vim.schedule(function()
                ui.stop_spinner()
                if vim.api.nvim_buf_is_valid(floats.bufnr) then
                    vim.api.nvim_buf_set_lines(floats.bufnr, 0, 1, false, { opts.message_finish .. " ✔" })
                    vim.bo[floats.bufnr].modifiable = false
                end
                CurrentJob = nil

                if opts.on_exit ~= nil then
                    opts.on_exit()
                end
            end)
        end,
    })

    -- clear previous output
    if vim.api.nvim_buf_is_valid(floats.bufnr) then
        vim.api.nvim_buf_set_lines(floats.bufnr, 0, -1, false, { opts.message_start .. "..." })
    end

    ui.start_spinner(floats.bufnr, opts.message_start)

    CurrentJob:start()
end

return M
