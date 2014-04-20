require 'js_base/js_test'

class TestJSTest < JSTest

  def test_generate_files
    enter_test_directory
    FileUtils.mkdir('z')

    generate_files('z',{
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

