local pickers = require("mvn.pickers")
local Job = require("plenary.job")
local job = require("mvn.job")
local ui = require("mvn.ui")
local log = require("mvn.log")

---@class Type
---@field id string
---@field name string
---@field description string
---@field action string
---@field tags table<string,string>

---@class Types
---@field values Type[]

---@class Value
---@field id string
---@field name string

---@generic T
---@class Values
---@field values Value[]
---@field type string
---@field default string

---@class Dependency
---@field name string
---@field values Value[]

---@class Dependencies
---@field type string
---@field values Dependency[]
---
---@class link
---@field href string
---@field templated boolean

---@class Spring
---@field _links table<string, link>
---@field type Types
---@field language Values
---@field bootVersion Values
---@field packaging Values
---@field javaVersion Values
---@field dependencies Dependencies
---@field groupId Values
---@field artifactId Values
---@field name Values
---@field description Values
---@field packageName Values

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

local picker_lists = {
    { key = "type",        label = "Project", },
    { key = "language",    label = "Language", },
    { key = "bootVersion", label = "Spring Boot", },
    { key = "packaging",   label = "Packaging", },
    { key = "javaVersion", label = "Java", },
}

local index = 1

local telescopeOpts = {}

---@param values Array
---@param func function|nil
local values = function(values, func)
    local items = {}

    for _, value in pairs(values) do
        if func == nil or func(value) then
            table.insert(items, { value.id, value.name })
        end
    end

    return items
end

local spring_request = function()
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

    local cwd = vim.fn.getcwd()
    local floats = ui.create_output({
        attach_mappings = function(map)
            map("n", "q", ui.quit)
        end
    })

    job.run(floats, {
        cmd = "curl",
        cwd = cwd,
        args = { "-L", "--location", url, "-o", springParams.artifactId .. '.zip' },
        message_start = "Project init...",
        message_finish = "Project spring boot created.",
        on_stderr = function() end,
        on_exit = function()
            vim.bo[floats.bufnr].modifiable = true
            job.run(floats, {
                cmd = "unzip",
                cwd = cwd,
                args = { springParams.artifactId .. ".zip" },
                message_start = "unzip",
                message_finish = "unzip",
            })
        end
    })
end

local pickers_choice = function(title, results, func)
    pickers.pickers_menu({
        title = title,
        results = results,
        make_entry = function(entry)
            return {
                value = entry[1],
                display = entry[2],
                ordinal = entry[2],
            }
        end,
        callback = function(selection)
            func(selection[1])
        end
    }, telescopeOpts)
end


---@param res Spring
local function run_next(res)
    local types = values(res.type.values, function(value)
        return value.action == '/starter.zip'
    end)
    local item = picker_lists[index]

    if not item then
        springParams.groupId = vim.fn.input("Group ID: ", res.groupId.default)
        springParams.artifactId = vim.fn.input("Artifact Id: ", res.artifactId.default)
        springParams.name = vim.fn.input("Name: ", springParams.artifactId)
        springParams.description = vim.fn.input("Description: ", res.description.default)
        springParams.packageName = vim.fn.input("Package Name: ",
            springParams.groupId .. "." .. springParams.artifactId)

        spring_request()
        return
    end

    local results

    if item.key == 'type' then
        results = types
    else
        results = values(res[item.key].values)
    end

    pickers_choice(item.label, results, function(selection)
        springParams[item.key] = selection

        index = index + 1

        run_next(res)
    end)
end

local M = {}

M.create_project = function(opts)
    telescopeOpts = opts or require("telescope.themes").get_dropdown({})

    Job:new({
        command = "curl",
        args = {
            "--header", "Accept: application/json",
            "--location", "https://start.spring.io"
        },
        on_exit = function(j)
            ---@type Spring
            local res = vim.json.decode(j:result()[1])

            vim.schedule(function()
                run_next(res)
            end)
        end
    }):start()
end

return M
