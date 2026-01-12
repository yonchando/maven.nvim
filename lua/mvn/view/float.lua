local Config = require("mvn.core.config")
local log = require("mvn.utils.log")

---@class MFloatOptions
---@field buf? number
---@field file? string
---@field margin? {top?:number, right?:number, bottom?:number, left?:number}
---@field size? {width:number, height:number}
---@field zindex? number
---@field style? "minimal"
---@field border? "none" | "single" | "double" | "rounded" | "solid" | "shadow"
---@field title? string
---@field title_pos? "center" | "left" | "right"
---@field noautocmd? boolean
---@field mapping? table<string, fun(self: MWinFloat)>
---@field wrap? boolean

---@class MWinFloat
---@field bufnr number
---@field win number
---@field opts MFloatOptions
---@field win_opts vim.api.keyset.win_config
---@field id number
---@field spinner_timer? uv.uv_timer_t
local M = {}

setmetatable(M, {
    __call = function(_, ...)
        return M.new(...)
    end,
})

local uv = vim.uv
local spinner_index = 1
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local _id = 0
local function next_id()
    _id = _id + 1
    return _id
end

---@param opts? MFloatOptions
M.new = function(opts)
    local self = setmetatable({}, { __index = M })
    return self:init(opts)
end

---@param opts? MFloatOptions
function M:init(opts)
    self.id = next_id()
    self.opts = vim.tbl_deep_extend("force", {
        size = Config.options.ui.size,
        style = "minimal",
        border = Config.options.ui.border or "none",
        backdrop = Config.options.ui.backdrop or 60,
        zindex = 50,
    }, opts or {})

    self.win_opts = {
        relative = 'editor',
        style = self.opts.style ~= "" and self.opts.style or 'minimal',
        border = self.opts.border,
        zindex = self.opts.zindex,
        noautocmd = self.opts.noautocmd,
        title = self.opts.title,
        title_pos = self.opts.title and self.opts.title_pos or nil
    }

    self.mapping = self.opts.mapping or {}

    self:mount()
end

function M:layout()
    local function size(max, value)
        return value > 1 and math.min(value, max) or math.floor(max * value)
    end
    self.win_opts.width = size(vim.o.columns, self.opts.size.width)
    self.win_opts.height = size(vim.o.lines, self.opts.size.height)

    self.win_opts.row = math.floor((vim.o.lines - self.win_opts.height) / 2)
    self.win_opts.col = math.floor((vim.o.columns - self.win_opts.width) / 2)

    if self.opts.border ~= "none" then
        self.win_opts.row = self.win_opts.row - 1
        self.win_opts.col = self.win_opts.col - 1
    end

    if self.opts.margin then
        if self.opts.margin.top then
            self.win_opts.height = self.win_opts.height - self.opts.margin.top
            self.win_opts.row = self.win_opts.row + self.opts.margin.top
        end
        if self.opts.margin.right then
            self.win_opts.width = self.win_opts.width - self.opts.margin.right
        end
        if self.opts.margin.bottom then
            self.win_opts.height = self.win_opts.height - self.opts.margin.bottom
        end
        if self.opts.margin.left then
            self.win_opts.width = self.win_opts.width - self.opts.margin.left
            self.win_opts.col = self.win_opts.col + self.opts.margin.left
        end
    end
end

function M:mount()
    self:layout()
    self.bufnr = vim.api.nvim_create_buf(false, true)
    self.win = vim.api.nvim_open_win(self.bufnr, true, self.win_opts)

    vim.api.nvim_set_current_buf(self.bufnr)

    for key, value in pairs(self.mapping) do
        vim.keymap.set("n", key, function()
            value(self)
        end, {
            buffer = self.bufnr,
            nowait = true,
            silent = true
        })
    end

    vim.keymap.set("n", "<esc>", function()
        self:close({ wipe = true })
    end, {
        buffer = self.bufnr,
        nowait = true,
        silent = true
    })

    vim.keymap.set("n", "q", function()
        self:close({ wipe = true })
    end, {
        buffer = self.bufnr,
        nowait = true,
        silent = true
    })
end

---@param opts? {wipe: boolean}
function M:close(opts)
    local buf = self.bufnr
    local win = self.win
    local wipe = opts and opts.wipe

    self.win = nil
    if wipe then
        self.bufnr = nil
    end

    vim.schedule(function()
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end

        if wipe and buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end

        vim.cmd.redraw()
    end)
end

function M:buf_valid()
    return self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr)
end

function M:win_valid()
    return self.win and vim.api.nvim_win_is_valid(self.win)
end

--- Creates a weak reference to an object.
--- Calling the returned function will return the object if it has not been garbage collected.
---@generic T: table
---@param obj T
---@return T|fun():T?
function M.weak(obj)
    local weak = { _obj = obj }
    ---@return table<any, any>
    local function get()
        local ret = rawget(weak, "_obj")
        return ret == nil and error("Object has been garbage collected", 2) or ret
    end
    local mt = {
        __mode = "v",
        __call = function(t)
            return rawget(t, "_obj")
        end,
        __index = function(_, k)
            return get()[k]
        end,
        __newindex = function(_, k, v)
            get()[k] = v
        end,
        __pairs = function()
            return pairs(get())
        end,
    }
    return setmetatable(weak, mt)
end

---@param events string|string[]
---@param fn fun(self:MWinFloat, event:{bufnr:number}):boolean?
---@param opts? vim.api.keyset.create_autocmd | {buffer: false, win?:boolean}
function M:on(events, fn, opts)
    opts = opts or {}
    if opts.win then
        opts.pattern = self.win .. ""
        opts.win = nil
    elseif opts.buffer == nil then
        opts.buffer = self.bufnr
    elseif opts.buffer == false then
        opts.buffer = nil
    end
    if opts.pattern then
        opts.buffer = nil
    end
    local _self = self.weak(self)
    opts.callback = function(e)
        local this = _self()
        if not this then
            -- delete the autocmd
            return true
        end
        return fn(this, e)
    end
    vim.api.nvim_create_autocmd(events, opts)
end

M.start_spinner = function(self, message)
    self.spinner_timer = uv.new_timer()

    if self.spinner_timer ~= nil then
        self.spinner_timer:start(
            0,
            100,
            vim.schedule_wrap(function()
                if not vim.api.nvim_buf_is_valid(self.bufnr) then
                    return
                end

                spinner_index = spinner_index % #spinner_frames + 1
                local frame = spinner_frames[spinner_index]

                vim.api.nvim_buf_set_lines(self.bufnr, 0, 1, false, { message .. " " .. frame })
            end)
        )
    end
end

M.stop_spinner = function(self)
    if self.spinner_timer then
        self.spinner_timer:stop()
        self.spinner_timer:close()
        self.spinner_timer = nil
    end
end

return M
