local MiniTest = require('mini.test')
local JavaTestParser = require('maven.parsers.java_test_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local function lines(text)
    return vim.split(text, '\n')
end

local junit5 = [[
package com.example;

import org.junit.jupiter.api.Test;

class FooTest {

  @Test
  void shouldSave() {
  }

  @ParameterizedTest
  @ValueSource(strings = { "a", "b" })
  void shouldParse(String value) {
  }

  @RepeatedTest(3)
  public void shouldRepeat() {}

  @TestFactory
  Stream<DynamicTest> dynamicTests() {
    return Stream.empty();
  }

  private void helper() {
  }
}
]]

T['parse JUnit 5 tests with mixed annotations'] = function()
    local result = JavaTestParser.parse(lines(junit5), '/project/src/test/java/FooTest.java')
    eq(result.class_name, 'FooTest')
    eq(result.methods, { 'shouldSave', 'shouldParse', 'shouldRepeat', 'dynamicTests' })
end

T['parse JUnit 4 test with annotation arguments'] = function()
    local source = [[
public class BarTest {
  @Test(expected = IllegalStateException.class)
  public void shouldFail() throws Exception {
  }
}
]]
    local result = JavaTestParser.parse(lines(source), 'BarTest.java')
    eq(result.class_name, 'BarTest')
    eq(result.methods, { 'shouldFail' })
end

T['parse annotation and method on the same line'] = function()
    local source = [[
class InlineTest {
  @Test void first() {}
  @Test @DisplayName("second (with parens)") void second() {}
}
]]
    local result = JavaTestParser.parse(lines(source), 'InlineTest.java')
    eq(result.methods, { 'first', 'second' })
end

T['skip annotations between @Test and the method'] = function()
    local source = [[
class ExtraTest {
  @Test
  @DisplayName("does a thing")
  @Timeout(5)

  void doesAThing() {
  }
}
]]
    local result = JavaTestParser.parse(lines(source), 'ExtraTest.java')
    eq(result.methods, { 'doesAThing' })
end

T['return nil when there are no tests'] = function()
    local source = [[
class Service {
  @Override
  public String toString() { return ""; }
}
]]
    eq(JavaTestParser.parse(lines(source), 'Service.java'), nil)
end

T['return nil for non java files'] = function()
    eq(JavaTestParser.parse(lines(junit5), 'FooTest.kt'), nil)
    eq(JavaTestParser.parse(lines(junit5), ''), nil)
end

return T
