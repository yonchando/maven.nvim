local MiniTest = require('mini.test')
local Console = require('maven.utils.console')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['highlights a passing test summary'] = function()
    eq(Console.line_highlights('[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0'), {
        { hl = 'DiagnosticInfo', col_start = 1, col_end = 5 },
        { hl = '@markup.strong', col_start = 7, col_end = 19 },
        { hl = 'DiagnosticOk', col_start = 21, col_end = 43 },
    })
end

T['highlights a failing test summary'] = function()
    local line = '[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 1, '
        .. 'Time elapsed: 0.1 s <<< FAILURE! -- in com.foo.BarTest'
    eq(Console.line_highlights(line), {
        { hl = 'DiagnosticError', col_start = 1, col_end = 6 },
        { hl = '@markup.strong', col_start = 8, col_end = 20 },
        { hl = 'DiagnosticError', col_start = 22, col_end = 33 },
        { hl = 'DiagnosticWarn', col_start = 46, col_end = 56 },
        { hl = 'DiagnosticError', col_start = 78, col_end = 90 },
    })
end

T['highlights the running test class'] = function()
    eq(Console.line_highlights('[INFO] Running com.foo.BarTest'), {
        { hl = 'DiagnosticInfo', col_start = 1, col_end = 5 },
        { hl = 'DiagnosticInfo', col_start = 7, col_end = 30 },
    })
end

T['keeps build result highlights'] = function()
    eq(Console.line_highlights('[INFO] BUILD SUCCESS'), {
        { hl = 'DiagnosticInfo', col_start = 1, col_end = 5 },
        { hl = 'DiagnosticOk', col_start = 7, col_end = 20 },
    })
end

return T
