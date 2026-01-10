# Maven.nvim

This is neovim plugin for running maven command.

![MavenCLI](./screen/maven-cli.png)
![MavenNewProject](./screen/maven-create-project.png)
![SpringBootStarter](./screen/spring-boot-starter.png)

## Features

- [x] Run Maven CLI (e.g. clean, compile, test, ...)
- [x] Create maven project command
- [x] Create spring boot project
- [ ] Run java application
- [x] Add spring boot dependencies to pom.xml
- [ ] Add maven dependencies from maven repository to pom.xml

## Requirement

- Neovim 0.11.0+
- command curl, unzip
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- mvn command in your env `PATH`

## Installation

### Lazy

```lua
{
    "https://github.com/yonchando/maven.nvim",
    dependencies = {
        {"nvim-telescope/telescope.nvim"},
    },
    config = function()
        local mvn = require("mvn")

        mvn.setup()

        vim.keymap.set("n","<leader>mvi", mvn.mvn_cli)
        vim.keymap.set("n","<leader>mvp", mvn.mvn_create_project)
        vim.keymap.set("n","<leader>spi", mvn.spring_initializr_project)
        vim.keymap.set("n","<leader>spd", mvn.spring_dependencies)
    end
}
```

## Usage

#### Commands

`:MvnCLI` maven command to execute

`:MvnNewProject` to generate `archetype:generate`

`:SpringStarter` to create spring boot application

`:SpringDependencies` to create spring boot application

#### Keymapping

`<Ctrl+i>` to select multiple `MvnCLI` to run at once

`<Ctrl+i>` to mark multiple `SpringDependencies` to inserts

