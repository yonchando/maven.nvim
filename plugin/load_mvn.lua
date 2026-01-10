local reload = function()
    package.loaded["mvn"] = nil
    package.loaded["mvn.ui"] = nil
    package.loaded["mvn.pickers"] = nil
    package.loaded["mvn.job"] = nil
    package.loaded["mvn.spring_project"] = nil
    package.loaded["mvn.spring_dependencies"] = nil
end

vim.keymap.set("n", "<leader>tt", function()
    local noice = require("noice")

    noice.notify("Spring Loading ... ", 1)
    reload()
    local mvn = require("mvn")
    mvn.spring_dependencies()
end)

vim.api.nvim_create_user_command("MvnCLI", function()
    local mvn = require("mvn")
    mvn.mvn_cli()
end, {})

vim.api.nvim_create_user_command("MvnNewProject", function()
    local mvn = require("mvn")
    mvn.mvn_create_project()
end, {})

vim.api.nvim_create_user_command("SpringStarter", function()
    local mvn = require("mvn")
    mvn.spring_initializr_project()
end, {})

vim.api.nvim_create_user_command("SpringDependencies", function()
    local mvn = require("mvn")
    mvn.spring_dependencies()
end, {})
