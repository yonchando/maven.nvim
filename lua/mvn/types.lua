---@class PluginConfig
---@field telescope_theme table|nil
---@field mvn_cmds string[]|nil
---@field archetypes table|nil

---@class value
---@field id string
---@field name string

---@class Type
---@field id string
---@field name string
---@field description string
---@field action string
---@field tags table<string,string>

---@class default
---@field type string
---@field default string

---@class Spring
---@field type {type: string, default: string, values: Type[]}
---@field bootVersion {type: string, values: value[]}
---
---@field groupId default
---@field artifactId default
---@field version default
---@field name default
---@field description default
---@field packageName default
