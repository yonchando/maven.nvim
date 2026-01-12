local M = {}

M.change_location = function(path)
    local stat = vim.uv.fs_stat(path)

    if stat == nil then
        return
    end

    vim.cmd("cd " .. path)

    local nvimtree_api_ok, nvimtree_api = pcall(require, "nvim-tree.api")

    if nvimtree_api_ok then
        nvimtree_api.tree.change_root(path)
        nvimtree_api.tree.reload()
    end
end

return M
