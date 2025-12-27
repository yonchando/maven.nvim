local reload = function()
    -- package.loaded["mvn"] = nil
    -- package.loaded["mvn.ui"] = nil
    -- package.loaded["mvn.pickers"] = nil
    -- package.loaded["mvn.job"] = nil
    -- package.loaded["mvn.spring"] = nil
end

vim.api.nvim_create_user_command("MavenCLI", function()
    reload()
    local mvn = require("mvn")
    mvn.mvn_cli(require("telescope.themes").get_dropdown({}))
end, {})

vim.api.nvim_create_user_command("MavenNewProject", function()
    reload()
    local mvn = require("mvn")
    mvn.mvn_create_project(require("telescope.themes").get_dropdown({}))
end, {})

vim.api.nvim_create_user_command("SpringBootStarter", function()
    reload()
    local mvn = require("mvn")
    mvn.spring_create_project(require("telescope.themes").get_dropdown({}))
end, {})
