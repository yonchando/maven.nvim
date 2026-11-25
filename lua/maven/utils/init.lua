local random = math.random
local M = {}

M.STARTED_STATE = 'STARTED'
M.SUCCEED_STATE = 'SUCCEED'
M.FAILED_STATE = 'FAILED'
M.PENDING_STATE = 'PENDING'

M.uuid = function()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

M.maven_data_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'maven')
M.maven_cache_path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'maven')

M.maven_local_repository_path = vim.fs.joinpath(vim.fn.expand('~'), '.m2', 'repository')

M.maven_plugin_xml_path = 'META-INF/maven/plugin.xml'

M.archetypes_catalog_url = 'https://repo.maven.apache.org/maven2/archetype-catalog.xml'

M.archetypes_json_path = vim.fs.joinpath(M.maven_data_path, 'archetypes.json')
M.local_catalog_path = vim.fs.joinpath(M.maven_local_repository_path, 'archetype-catalog.xml')

M.local_central_catalog_path =
    vim.fs.joinpath(M.maven_local_repository_path, 'archetype-catalog-central.xml')

M.get_plugin_root_dir = function()
    local source = debug.getinfo(1).source

    if jit and jit.os and string.lower(jit.os) == 'windows' then
        source = source:gsub('/', '\\')
    end

    local dir_path = source:match('@(.*/)') or source:match('@(.*\\)')
    if dir_path == nil then
        return nil
    end
    return dir_path .. '..'
end

M.humanize_size = function(size)
    if not size then
        return nil
    end
    local units = { 'B', 'KB', 'MB', 'GB', 'TB' }
    local unit_index = 1

    while size >= 1024 and unit_index < #units do
        size = size / 1024
        unit_index = unit_index + 1
    end
    return string.format('%.2f %s', size, units[unit_index])
end

M.path_separator = (function()
    if jit then
        local os = string.lower(jit.os)
        if os ~= 'windows' then
            return '/'
        else
            return '\\'
        end
    else
        return package.config:sub(1, 1)
    end
end)()

M.get_jar_file_path = function(group_id, artifact_id, version)
    return vim.fs.joinpath(
        M.maven_local_repository_path,
        group_id:gsub('%.', M.path_separator),
        artifact_id,
        version,
        artifact_id .. '-' .. version .. '.jar'
    )
end

local opposite_side = { left = 'right', right = 'left', top = 'below', bottom = 'above' }

---Open a top-level editor split on the side opposite to the projects view
---@param bufnr integer buffer to show in the new window
---@param enter boolean whether to focus the new window
---@return integer winid
M.open_editor_split = function(bufnr, enter)
    local position = require('maven.config').options.projects_view.position
    return vim.api.nvim_open_win(bufnr, enter, {
        split = opposite_side[position] or 'left',
        win = -1,
    })
end

---Check whether a window is a normal (non-floating) window that is not the projects view
---@param winid integer
---@return boolean
M.is_editor_win = function(winid)
    if not winid or winid == 0 or not vim.api.nvim_win_is_valid(winid) then
        return false
    end
    if vim.api.nvim_win_get_config(winid).relative ~= '' then
        return false
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    return vim.api.nvim_get_option_value('filetype', { buf = bufnr }) ~= 'maven'
end

return M
