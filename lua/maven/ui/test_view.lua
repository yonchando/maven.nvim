local Layout = require('nui.layout')
local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local highlights = require('maven.config.highlights')
local MavenConfig = require('maven.config')
local CommandBuilder = require('maven.utils.cmd_builder')
local Console = require('maven.utils.console')
local Utils = require('maven.utils')

---@class TestView
---@field private _entries TestEntry[]
---@field private _visible_entries TestEntry[]
---@field private _input_component NuiInput
---@field private _options_component NuiPopup
---@field private _options_tree NuiTree
---@field private _prev_win number
---@field private _default_opts table
---@field private _layout NuiLayout
local TestView = {}
TestView.__index = TestView

---@param entries TestEntry[]
---@return TestView
function TestView.new(entries)
    return setmetatable({
        _entries = entries,
        _visible_entries = entries,
        _default_opts = {
            ns_id = MavenConfig.namespace,
            buf_options = {
                buftype = 'nofile',
                swapfile = false,
                filetype = 'maven',
                undolevels = -1,
            },
            win_options = {
                colorcolumn = '',
                signcolumn = 'no',
                number = false,
                relativenumber = false,
                spell = false,
                list = false,
            },
        },
    }, TestView)
end

---Run a test entry
---@param entry TestEntry
local function run_test(entry)
    local command =
        CommandBuilder.build_mvn_cmd(entry.pom_xml_path, { 'test', '-Dtest=' .. entry.test_arg })
    local show_output = MavenConfig.options.console.show_command_execution
    Console.execute_command(command.cmd, command.args, show_output, function(state)
        vim.schedule(function()
            if Utils.FAILED_STATE == state then
                vim.notify('Failed test execution: ' .. entry.name, vim.log.levels.ERROR)
            end
        end)
    end)
end

---@private Close the view and go back to the previous window
function TestView:_close()
    self._layout:unmount()
    if vim.api.nvim_win_is_valid(self._prev_win) then
        vim.api.nvim_set_current_win(self._prev_win)
    end
end

---@private Close the view and run the entry
---@param entry? TestEntry
function TestView:_run(entry)
    if not entry then
        return
    end
    self:_close()
    run_test(entry)
end

---@private Render the visible entries
function TestView:_render_entries()
    local nodes = {}
    for _, entry in ipairs(self._visible_entries) do
        table.insert(nodes, Tree.Node({ text = entry.name, entry = entry }))
    end
    self._options_tree:set_nodes(nodes)
    self._options_tree:render()
end

---@private Create the options tree list
function TestView:_create_options_tree_list()
    self._options_tree = Tree({
        ns_id = MavenConfig.namespace,
        bufnr = self._options_component.bufnr,
        prepare_node = function(node)
            local line = Line()
            line:append(' ')
            line:append(MavenConfig.options.icons.tool, highlights.SPECIAL)
            line:append(' ' .. node.text, highlights.INFO)
            if node.entry.description then
                line:append(' (' .. node.entry.description .. ')', highlights.COMMENT)
            end
            return line
        end,
    })
    self:_render_entries()
end

---@private On input change handler
---@param query string
function TestView:_on_input_change(query)
    query = string.lower(vim.trim(query))
    vim.schedule(function()
        local visible = {}
        for _, entry in ipairs(self._entries) do
            if query == '' or string.find(string.lower(entry.name), query, 1, true) then
                table.insert(visible, entry)
            end
        end
        self._visible_entries = visible
        self:_render_entries()
        if self._options_component.winid and #visible > 0 then
            vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
        end
    end)
end

---@private Create the input component
function TestView:_create_input_component()
    local view_options = MavenConfig.options.test_view
    self._input_component = Input({
        enter = true,
        ns_id = MavenConfig.namespace,
        relative = 'win',
        position = { row = 1, col = 0 },
        size = { width = '100%', height = 20 },
        zindex = 60,
        border = {
            text = { top = ' Run Maven Test ', top_align = 'center' },
            style = view_options.input_win.border.style,
            padding = view_options.input_win.border.padding or { 0, 0, 0, 0 },
        },
    }, {
        prompt = Text(MavenConfig.options.icons.search .. '  ', highlights.SPECIAL),
        on_submit = function()
            vim.schedule(function()
                self:_run(self._visible_entries[1])
            end)
        end,
        on_change = function(query)
            self:_on_input_change(query)
        end,
    })
    local function move_next()
        vim.api.nvim_set_current_win(self._options_component.winid)
        vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
    end
    self._input_component:map('i', { '<C-n>', '<Down>' }, move_next, { noremap = true })
    self._input_component:map('n', { 'j', '<C-n>', '<Down>' }, move_next, { noremap = true })
    self._input_component:map('n', { '<esc>', 'q' }, function()
        self:_close()
    end, { noremap = true })
end

---@private Create the options component
function TestView:_create_options_component()
    local view_options = MavenConfig.options.test_view
    self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
        win_options = { cursorline = true, winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT },
        border = {
            style = view_options.options_win.border.style,
            padding = view_options.options_win.border.padding or { 0, 0, 0, 0 },
        },
    }))
    self:_create_options_tree_list()
    self._options_component:map('n', '<enter>', function()
        local node = self._options_tree:get_node()
        if node then
            self:_run(node.entry)
        end
    end)
    self._options_component:map('n', { 'i' }, function()
        vim.api.nvim_set_current_win(self._input_component.winid)
        vim.cmd('startinsert!')
    end)
    self._options_component:map('n', { '<esc>', 'q' }, function()
        self:_close()
    end)
end

---@private Create the layout
function TestView:_create_layout()
    self._layout = Layout(
        {
            ns_id = MavenConfig.namespace,
            relative = 'editor',
            position = '50%',
            size = MavenConfig.options.test_view.size,
        },
        Layout.Box({
            Layout.Box(self._input_component, { size = { height = 1, width = '100%' } }),
            Layout.Box(self._options_component, { size = '100%' }),
        }, { dir = 'col' })
    )
    self._layout:mount()
    for _, component in pairs({ self._input_component, self._options_component }) do
        component:on('BufLeave', function()
            vim.schedule(function()
                local current_bufnr = vim.api.nvim_get_current_buf()
                for _, p in pairs({ self._input_component, self._options_component }) do
                    if p.bufnr == current_bufnr then
                        return
                    end
                end
                self._layout:unmount()
            end)
        end)
    end
end

---Mount the window view
function TestView:mount()
    self._prev_win = vim.api.nvim_get_current_win()
    self:_create_options_component()
    self:_create_input_component()
    self:_create_layout()
end

return TestView
