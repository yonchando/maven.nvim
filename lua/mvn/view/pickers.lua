local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Config = require("mvn.core.config")

local M = {}

---@class PickerMenuConfig
---@field title string
---@field results table
---@field callback function
---@field mapping function|nil
---@field make_entry function|nil

---@param opts PickerMenuConfig
M.pickers_menu = function(opts)
    local entry_maker = function(entry)
        if opts.make_entry == nil then
            return {
                value = entry,
                display = entry,
                ordinal = entry,
            }
        else
            return opts.make_entry(entry)
        end
    end

    pickers.new(Config.options.telescope_theme, {
        prompt_title = opts.title,
        finder = finders.new_table({
            results = opts.results,
            entry_maker = entry_maker
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            if opts.mapping ~= nil then
                opts.mapping(prompt_bufnr, map)
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

                vim.schedule(function()
                    opts.callback(selection_entry)
                end)
            end)

            return true
        end
    }):find()
end

return M
