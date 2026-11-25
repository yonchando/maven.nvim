# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`maven.nvim` is a Neovim (>= 0.10) plugin for working with Maven projects: browsing projects/modules, running lifecycles, plugin goals and custom commands, inspecting dependencies, creating projects from archetypes, and managing favorite commands. Its only runtime dependency is `nui.nvim` (Plenary was removed; use `vim.system`/`vim.loop` instead). Unix needs `unzip` to read plugin jars.

## Commands

- Run all tests: `./scripts/test.sh` (runs `nvim --headless --noplugin -u tests/minit.lua -c "lua MiniTest.run()"`)
- Run one test file:
  `nvim --headless --noplugin -u tests/minit.lua -c "lua MiniTest.run_file('tests/parsers/pom_xml_parser_spec.lua')"`
- Format: `stylua .` — check only (what CI runs): `stylua --check .`

`tests/minit.lua` clones `mini.test` and `nui.nvim` into `/tmp/mini.test` and `/tmp/nui.nvim` on first run (override with `MINITEST_DIR` / `NUI_DIR`). Test files must match `tests/**/*_spec.lua` and use `MiniTest.new_set()` with `MiniTest.expect.equality`.

Style is enforced by `.stylua.toml`: 4-space indent, 100 columns, single quotes preferred, call parentheses always. CI (`.github/workflows/ci.yml`) runs the stylua check and the tests on Neovim nightly.

## Architecture

All code lives under `lua/maven/`; `plugin/maven.lua` only defines the user commands (`:Maven`, `:MavenExec`, `:MavenInit`, `:MavenFavorites`, `:MavenTest`), which delegate to `require('maven')`.

- **`init.lua`** — public API. `setup()` initializes config, sources and highlights. It holds singleton view instances (projects, execution, initializer, arguments) that are lazily created and re-mounted/toggled.
- **`config/`** — `MavenConfig.options` is the merged user/default config, read globally by every other module (README documents the defaults). `highlights.lua` defines the `Maven*` highlight groups.
- **`sources/`** — the data layer. `sources/init.lua` scans the workspace for `pom.xml` files (recursively following `<modules>`, depth bounded by `project_scanner_depth`), builds `Project` trees, and loads dependencies, plugins, help options, archetypes and favorites — either from cache or by running `mvn` and parsing the result. `sources/project.lua` defines the domain classes (`Project`, `Command`, `Lifecycle`, `Dependency`, `Plugin`, `Goal`, `Favorite`); runnable items expose `as_favorite()`.
- **`parsers/`** — pure-ish functions turning text/files into domain data: `pom.xml`, effective POM, `dependency:tree` output, `plugin.xml` from jars, `mvn --help` output, archetype catalogs, plus `*_cache_parser.lua` modules that read/write JSON caches. These are the main unit-tested surface. XML is parsed with the vendored `vendor/xml2lua` (don't modify vendored code); note single vs. repeated XML elements come back as a table vs. a list, so parsers check `vim.islist`.
- **`utils/`**
  - `cmd_builder.lua` builds `{cmd, args}` for every Maven invocation (respecting `mvn_executable` and default arguments).
  - `queue.lua` is a promise-like job queue over `vim.system` (concurrency 1 by default) with `:next`/`:catch`.
  - `console.lua` owns the single shared console buffer and the global queue; `execute_command(cmd, args, show_output, callback, cwd)` reports progress through `callback(state, result)` with states `PENDING`/`STARTED`/`SUCCEED`/`FAILED` from `utils/init.lua`. Whether output is shown is controlled per command type by `console.show_*` options.
  - `utils/init.lua` holds shared paths (`stdpath('cache')/maven`, `stdpath('data')/maven`, `~/.m2/repository`).
- **`ui/`** — `nui.nvim`-based views. `projects_view.lua` is the main side-panel tree (projects → lifecycles, dependencies, plugins/goals, commands, favorites) and launches the other views (dependencies, execution, help, initializer, arguments, favorites).

### Caching

Each scanned project path is registered in `cache/maven/projects.json` with a generated UUID key; per-project caches (dependencies, plugins, favorites) are stored under that key. Cache usage is toggled by `cache.enable_*` options, and `load_*` functions take a `force` flag to bypass the cache.

### Async conventions

Maven runs asynchronously via `vim.system`; callbacks fire off the main loop, so any buffer/UI work in callbacks must be wrapped in `vim.schedule`.
