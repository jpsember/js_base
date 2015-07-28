# A Ruby script with property that it lies in a different
# directory from the other test files
#

require 'js_base/js_test'

def misc_test_from_our_dir
  from_our_dir do
    current_dir = File.absolute_path(Dir.pwd)
    script_dir = File.absolute_path(File.dirname(__FILE__))
    assert_equal(current_dir,script_dir)
  end
end
