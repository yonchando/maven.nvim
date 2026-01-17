local reload = function()
    package.loaded["mvn"] = nil
    package.loaded["mvn.features.spring_project"] = nil
    package.loaded["mvn.features.spring_dependencies"] = nil
    package.loaded["mvn.features.mvn_cli"] = nil
    package.loaded["mvn.features.mvn_archetype"] = nil
end

vim.keymap.set("n", "<leader>tt", function()
    reload()
    local mvn = require("mvn")
    mvn.test()
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
