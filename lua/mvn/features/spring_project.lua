local pickers = require("mvn.view.pickers")
local Float = require("mvn.view.float")
local Job = require("plenary.job")
local job = require("mvn.utils.job")
local stats = require("mvn.stats")
local util = require("mvn.util")
local log = require("mvn.utils.log")

---@class SpringParams
local springParams = {
    type = nil,
    language = nil,
    bootVersion = nil,
    groupId = nil,
    artifactId = nil,
    name = nil,
    description = nil,
    packageName = nil,
    packaging = nil,
    javaVersion = nil,
}

---@class SpringPicker
local picker_lists = {
    { value = 1, key = "type",        label = "Project", },
    { value = 1, key = "language",    label = "Language", },
    { value = 2, key = "bootVersion", label = "Spring Boot", },
    { value = 1, key = "packaging",   label = "Packaging", },
    { value = 1, key = "javaVersion", label = "Java", },
}

local index = 1

---@class SpringProject
---@field results Spring
local M = {}

---@param values value[]
M.values = function(values)
    local items = {}

    for _, value in pairs(values) do
        table.insert(items, { value.id, value.name })
    end

    return items
end

---@param item {key: string, label: string, value: number}
M.pickers_choice = function(item, results, func)
    pickers.pickers_menu({
        title = item.label,
        results = results,
        make_entry = function(entry)
            return {
                value = entry[item.value],
                display = entry[2],
                ordinal = entry[2],
            }
        end,
        callback = function(selection)
            func(selection[1])
        end
    })
end

function M:spring_request()
    local query = ""

    for key, value in pairs(springParams) do
        if key ~= "description" then
            query = query .. key .. "=" .. value .. "&"
        else
            query = query .. key .. "=" .. vim.uri_encode(value) .. "&"
        end
    end

    query = query .. "baseDir=" .. springParams.artifactId

    local url = "https://start.spring.io/starter.zip?" .. query

    self.cwd = vim.fn.getcwd()
    stats.float = setmetatable({}, { __index = Float })
    stats.float:init()

    stats.float:on("WinClosed", function()
        util.change_location(self.cwd .. "/" .. springParams.artifactId)
    end)

    job.run({
        cmd = "curl",
        cwd = self.cwd,
        args = { "-L", "--location", url, "-o", springParams.artifactId .. '.zip' },
        message_start = "Project init...",
        message_finish = "Project spring boot created.",
        on_exit = function()
            vim.bo[stats.float.bufnr].modifiable = true

            job.run({
                cmd = "unzip",
                cwd = self.cwd,
                args = { springParams.artifactId .. ".zip" },
                message_start = "unzip",
                message_finish = "unzip",
            })
        end
    })
end

M.run_next = function(self)
    local item = picker_lists[index]

    if not item then
        springParams.groupId = vim.fn.input("Group ID: ", self.results.groupId.default)
        springParams.artifactId = vim.fn.input("Artifact Id: ", self.results.artifactId.default)
        springParams.name = vim.fn.input("Name: ", springParams.artifactId)
        springParams.description = vim.fn.input("Description: ", self.results.description.default)
        springParams.packageName = vim.fn.input("Package Name: ",
            springParams.groupId .. "." .. springParams.artifactId)

        self:spring_request()
        return
    end

    local results

    if item.key == 'type' then
        local types = vim.tbl_filter(function(value)
            return value.action == '/starter.zip'
        end, self.results.type.values)

        results = self.values(types)
    else
        results = self.values(self.results[item.key].values)
    end

    self.pickers_choice(item, results, function(selection)
        springParams[item.key] = selection

        index = index + 1

        self:run_next()
    end)
end

M.initialzr = function(self)
    index = 1

    if self.results ~= nil then
        M:run_next()
        return
    end

    Job:new({
        command = "curl",
        args = {
            "--header", "Accept: application/json",
            "--location", "https://start.spring.io"
        },
        on_exit = function(j)
            vim.schedule(function()
                if j:result() then
                    ---@type Spring
                    self.results = vim.json.decode(j:result()[1])
                    M:run_next()
                end
            end)
        end
    }):start()
end

return M
