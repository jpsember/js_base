#!/usr/bin/env ruby

require 'js_base/test'

class TestTest < Test::Unit::TestCase

  def setup
    enter_test_directory
  end

  def teardown
    leave_test_directory
  end

  def test_generate
    FileUtils.mkdir('z')

    TestUtils.generate_files('z',{
      'a' => {
        'b.txt' => 'b contents',
        'c' => {
          'd.txt' => 'd contents'
        }
        },
        'e.txt' => 'e.txt'
        })

    assert(File.exist?('z/a/b.txt'))
    assert(File.exist?('z/a/c/d.txt'))
    assert(File.exist?('z/e.txt'))
  end

end
