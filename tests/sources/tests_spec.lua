local MiniTest = require('mini.test')
local Tests = require('maven.sources.tests')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local root

local function write(path, content)
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    vim.fn.writefile(vim.split(content, '\n'), path)
end

T['tests source'] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            root = vim.fn.tempname()
            write(root .. '/pom.xml', '<project><artifactId>parent</artifactId></project>')
            write(root .. '/mod-a/pom.xml', '<project><artifactId>mod-a</artifactId></project>')
            write(
                root .. '/mod-a/src/test/java/a/ATest.java',
                'class ATest {\n  @Test\n  void first() {}\n}'
            )
            write(
                root .. '/mod-a/src/main/java/a/A.java',
                'class A {\n  @Test\n  void notATest() {}\n}'
            )
            write(root .. '/mod-b/src/test/java/b/Helper.java', 'class Helper {}')
        end,
        post_case = function()
            vim.fn.delete(root, 'rf')
        end,
    },
})

T['tests source']['find nearest pom from a nested file'] = function()
    eq(Tests.find_pom(root .. '/mod-a/src/test/java/a/ATest.java'), root .. '/mod-a/pom.xml')
    eq(Tests.find_pom(root .. '/mod-b/src/test/java/b/Helper.java'), root .. '/pom.xml')
end

T['tests source']['list tests of every module with their own pom'] = function()
    local entries = Tests.from_project(root .. '/pom.xml')
    eq(#entries, 2)
    eq(entries[1].name, 'ATest')
    eq(entries[1].test_arg, 'ATest')
    eq(entries[1].description, 'mod-a/src/test/java/a/ATest.java')
    eq(entries[1].pom_xml_path, root .. '/mod-a/pom.xml')
    eq(entries[2].name, 'ATest#first')
    eq(entries[2].test_arg, 'ATest#first')
    eq(entries[2].pom_xml_path, root .. '/mod-a/pom.xml')
end

T['tests source']['list tests of a buffer'] = function()
    local file = root .. '/mod-a/src/test/java/a/ATest.java'
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
    local entries = Tests.from_buffer(vim.api.nvim_get_current_buf())
    eq(#entries, 2)
    eq(entries[2].name, 'ATest#first')
    vim.cmd('bwipeout!')
end

T['tests source']['return nil for a buffer without tests'] = function()
    vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/mod-b/src/test/java/b/Helper.java'))
    eq(Tests.from_buffer(vim.api.nvim_get_current_buf()), nil)
    vim.cmd('bwipeout!')
end

return T
