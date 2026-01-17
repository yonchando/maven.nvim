local pickers = require("mvn.view.pickers")
local Job = require("plenary.job")
local log = require("mvn.utils.log")
local Float = require("mvn.view.float")

---@type MWinFloat
local window

---@class dependency
---@field groupId string
---@field artifactId string
---@field scope string
local M = {}

local dependencies = {}
local current_version = nil

function M:spring_dependencies_listing()
    vim.schedule(function()
        local results = {}

        for key, value in pairs(dependencies.dependencies) do
            table.insert(results, {
                name = key,
                value = value
            })
        end
        pickers.pickers_menu({
            title = "Choose dependencies",
            make_entry = function(entry)
                return {
                    value = entry.value,
                    display = entry.name,
                    ordinal = entry.name,
                }
            end,
            results = results,
            callback = function(selection)
                local cursor = vim.api.nvim_win_get_cursor(0)
                local bufnr = vim.api.nvim_get_current_buf()
                local content = {}

                for _, value in pairs(selection) do
                    table.insert(content, "  <dependency>")

                    table.insert(content, "    <groupId>" .. value.groupId .. "</groupId>")

                    table.insert(content, "    <artifactId>" .. value.artifactId .. "</artifactId>")

                    table.insert(content, "  </dependency>")
                    table.insert(content, "")
                end

                local line = cursor[1]

                vim.api.nvim_buf_set_lines(bufnr, line, line, true, content)
            end
        })
    end)
end

function M:spring_dependencies()
    local j = Job:new({
        command = "curl",
        args = {
            "--header", "Accept: application/json",
            "--location", "https://start.spring.io/dependencies?bootVersion=" .. current_version
        },
        on_stderr = function(error)
            if error then
                log.error(error)
            end
        end,
        on_exit = function(j, code)
            vim.schedule(function()
                if code ~= 0 then
                    vim.api.nvim_buf_set_lines(window.bufnr, -1, -1, false, j:stderr_result())
                else
                    window:close({ wipe = true })
                    if j:result()[1] ~= nil then
                        dependencies = vim.json.decode(j:result()[1])

                        self:spring_dependencies_listing()
                    end
                end
            end)
        end
    })

    j:start()

    window:on("WinClosed", function()
        j:shutdown()
    end)
end

function M:spring_versions()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    ---@param s string
    ---@return string
    local trim = function(s)
        return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
    end

    current_version = nil
    local versionStart
    local parentStart, parentEnd

    for linenr, line in ipairs(lines) do
        line = trim(line)

        if line ~= "" then
            current_version = line:gmatch("<version>(%d.+)</version>")()

            versionStart = line:match("<version>")

            if not parentStart then
                parentStart = line:match("<parent>")
            end

            parentEnd = line:match("</parent>")

            if current_version and parentStart then
                break
            end

            if versionStart and parentStart then
                current_version = trim(lines[linenr + 1])
            end

            if current_version or parentEnd then
                break
            end
        end
    end
end

M.choose_dependencies = function()
    local self = setmetatable({}, { __index = M })

    self:spring_versions()

    if current_version then
        window = Float.new({
            size = {
                height = 0.5,
                width = 0.5
            }
        })
        vim.api.nvim_set_option_value("wrap", true, {
            win = window.win
        })
        window:start_spinner("Loading...")
        self:spring_dependencies()
    else
        log.error("Can't find <version>...</version> tag in <parent>...</parent> tag.")
    end
end

return M
