local JavaTestParser = require('maven.parsers.java_test_parser')
local FileUtils = require('maven.utils.fs')

---@class TestEntry
---@field name string
---@field description string
---@field pom_xml_path string
---@field test_arg string value passed to -Dtest

local M = {}

local test_file_pattern = '[/\\]src[/\\]test[/\\].+%.java$'

local scan_depth = 20

---Find the nearest pom.xml going upward from a path
---@param path string file or directory
---@return string|nil
M.find_pom = function(path)
    if not path or path == '' then
        return nil
    end
    local root = vim.fs.root(path, 'pom.xml')
    if not root then
        return nil
    end
    return vim.fs.joinpath(root, 'pom.xml')
end

---Build the entries of a test class
---@param file_path string
---@param test_class JavaTestClass
---@param description string
---@return TestEntry[]
local function entries_for(file_path, test_class, description)
    local pom_xml_path = M.find_pom(file_path)
    if not pom_xml_path then
        return {}
    end
    local class_name = test_class.class_name
    local entries = {
        {
            name = class_name,
            description = description,
            pom_xml_path = pom_xml_path,
            test_arg = class_name,
        },
    }
    for _, method in ipairs(test_class.methods) do
        local name = class_name .. '#' .. method
        table.insert(entries, {
            name = name,
            description = 'Run test',
            pom_xml_path = pom_xml_path,
            test_arg = name,
        })
    end
    return entries
end

---Load the tests of a buffer
---@param bufnr number
---@return TestEntry[]|nil nil when the buffer has no tests
M.from_buffer = function(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local test_class = JavaTestParser.parse(lines, file_path)
    if not test_class then
        return nil
    end
    local entries = entries_for(file_path, test_class, 'Run all tests in class')
    return #entries > 0 and entries or nil
end

---Load the tests of every module under a pom.xml
---@param pom_xml_path string
---@return TestEntry[]
M.from_project = function(pom_xml_path)
    local root = vim.fs.dirname(pom_xml_path)
    local files = {}
    FileUtils.scan_dir_async(root, {
        depth = scan_depth,
        search_pattern = test_file_pattern,
        on_insert = function(path)
            table.insert(files, path)
        end,
    })
    table.sort(files)
    local entries = {}
    for _, file_path in ipairs(files) do
        local test_class = JavaTestParser.parse(FileUtils.read_lines(file_path), file_path)
        if test_class then
            local relative_path = file_path:sub(#root + 2)
            vim.list_extend(entries, entries_for(file_path, test_class, relative_path))
        end
    end
    return entries
end

return M
