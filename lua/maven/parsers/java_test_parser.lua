---@class JavaTestClass
---@field class_name string
---@field methods string[]

local JavaTestParser = {}

local test_annotations = {
    Test = true,
    ParameterizedTest = true,
    RepeatedTest = true,
    TestFactory = true,
    TestTemplate = true,
}

---Return the annotation name if the line starts with an annotation
---@param line string
---@return string|nil
local function match_annotation(line)
    return string.match(line, '^%s*@([%w_]+)')
end

---Remove leading annotations (with optional arguments) from a line
---@param line string
---@return string
local function strip_annotations(line)
    local rest = line
    while true do
        local stripped = string.gsub(rest, '^%s*@[%w_.]+%b()', '', 1)
        if stripped == rest then
            stripped = string.gsub(rest, '^%s*@[%w_.]+', '', 1)
        end
        if stripped == rest then
            return rest
        end
        rest = stripped
    end
end

---Parse the test methods of a Java source file
---@param lines string[]
---@param file_name string
---@return JavaTestClass|nil
JavaTestParser.parse = function(lines, file_name)
    if not file_name or not string.match(file_name, '%.java$') then
        return nil
    end
    local methods = {}
    local seen = {}
    local has_tests = false
    local pending = false
    for _, line in ipairs(lines) do
        local annotation = match_annotation(line)
        if annotation and test_annotations[annotation] then
            has_tests = true
            pending = true
        end
        if pending then
            local code = strip_annotations(line)
            local method = string.match(code, '([%w_$]+)%s*%(')
            if method then
                pending = false
                if not seen[method] then
                    seen[method] = true
                    table.insert(methods, method)
                end
            end
        end
    end
    if not has_tests then
        return nil
    end
    return {
        class_name = vim.fn.fnamemodify(file_name, ':t:r'),
        methods = methods,
    }
end

return JavaTestParser
