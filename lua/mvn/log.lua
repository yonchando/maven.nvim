local M = {}
M.info = function(value, inspect)
    inspect = inspect or true
    if inspect then
        vim.notify(vim.inspect(value), vim.log.levels.INFO)
    else
        vim.notify(value, vim.log.levels.INFO)
    end
end
M.error = function(value)
    vim.notify(vim.inspect(value), vim.log.levels.ERROR)
end
M.debug = function(value)
    vim.notify(vim.inspect(value), vim.log.levels.DEBUG)
end
M.warn = function(value)
    vim.notify(vim.inspect(value), vim.log.levels.WARN)
end
return M
