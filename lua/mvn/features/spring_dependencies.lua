local pickers = require("mvn.view.pickers")
local Job = require("plenary.job")
local log = require("mvn.utils.log")

---@class dependency
---@field groupId string
---@field artifactId string
---@field scope string
local M = {}

local versions = {}
local dependencies = {}
local current_version = nil

---@param values Array
local values = function(values)
    local items = {}

    for _, value in pairs(values) do
        table.insert(items, { value.id, value.name })
    end

    return items
end

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
    Job:new({
        command = "curl",
        args = {
            "--header", "Accept: application/json",
            "--location", "https://start.spring.io/dependencies?bootVersion=" .. current_version
        },
        on_stderr = function(error)
            if error then
                log.info({
                    error = error
                })
            end
        end,
        on_exit = function(j)
            if j:result()[1] ~= nil then
                dependencies = vim.json.decode(j:result()[1])

                self:spring_dependencies_listing()
            end
        end
    }):start()
end

function M:spring_versions()
    pickers.pickers_menu({
        title = "Spring version",
        make_entry = function(entry)
            return {
                value = entry[1],
                display = entry[2],
                ordinal = entry[2],
            }
        end,
        results = versions,
        callback = function(version)
            current_version = version[1]
            self:spring_dependencies()
        end
    })
end

M.choose_dependencies = function()
    if current_version ~= nil then
        M:spring_dependencies()
        return
    end

    if #versions > 0 then
        M:spring_versions()
    else
        Job:new({
            command = 'curl',
            args = {
                '--header', 'Accept: application/json',
                '--location', 'https://start.spring.io'
            },
            on_exit = function(j)
                vim.schedule(function()
                    if j:result()[1] ~= nil then
                        ---@type Spring
                        local spring = vim.json.decode(j:result()[1])
                        versions = values(spring.bootVersion.values)
                        M:spring_versions()
                    end
                end)
            end
        }):start()
    end
end

return M
