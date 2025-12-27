local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local log = require("mvn.log")

local M = {}

---@class Config
---@field title string
---@field results table
---@field callback function
---@field mapping function|nil
---@field make_entry function|nil

---@param config Config
---@param opts table
M.pickers_menu = function(config, opts)
    opts = opts or {}

    local entry_maker = function(entry)
        if config.make_entry == nil then
            return {
                value = entry,
                display = entry,
                ordinal = entry,
            }
        else
            return config.make_entry(entry)
        end
    end

    pickers.new(opts, {
        prompt_title = config.title,
        finder = finders.new_table({
            results = config.results,
            entry_maker = entry_maker
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            if opts.mapping ~= nil then
                opts.mappings(map, actions, action_state)
            end

            actions.select_default:replace(function()
                local picker = action_state.get_current_picker(prompt_bufnr)
                local multi = picker:get_multi_selection()

                actions.close(prompt_bufnr)

                local selection = action_state.get_selected_entry()

                local selection_entry = {}

                for _, entry in pairs(multi) do
                    if entry.value ~= selection.value then
                        table.insert(selection_entry, entry.value)
                    end
                end

                table.insert(selection_entry, selection.value)

                config.callback(selection_entry)
            end)

            return true
        end
    }):find()
end

return M
