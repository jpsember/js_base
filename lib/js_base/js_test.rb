require 'minitest/autorun'
require 'js_base'
require 'js_base/test_snapshot'

class JSTest < Minitest::Test

  attr_accessor :swizzler

  def setup
    super
    @original_directory = nil
    @test_dir = nil
    @saved_stdout = nil
    self.swizzler = Swizzler.new
  end

  def teardown
    leave_test_directory if @original_directory
    self.swizzler.remove_all
    super
  end

  # Create a temporary subdirectory for test purposes, and make it the current directory.
  #
  # @param subdirectory_name the name of the subdirector(ies) to create,
  #  as a subdirectory of the calling script's directory; if nil, derives it from
  #  the calling script's name.
  #
  def enter_test_directory(subdirectory_name = nil)
    c = caller()[0]
    c = c[0...c.index(':')]
    script_path = File.dirname(c)
    if !subdirectory_name
      subdirectory_name = File.basename(c,'.rb')
      if subdirectory_name.start_with? 'test_'
        subdirectory_name.slice!(0...5)
      end
      subdirectory_name.insert(0,'temporary_')
    end

    @test_dir = File.join(script_path,subdirectory_name)
    FileUtils.mkdir_p(@test_dir)

    @original_directory = Dir.pwd
    Dir.chdir(@test_dir)
  end

  # Restore the original directory, and optionally delete the test directory
  #
  def leave_test_directory(retain = false)
    raise IllegalStateException, "No test directory found" if !@original_directory
    Dir.chdir(@original_directory)
    @original_directory = nil
    FileUtils.rm_rf(@test_dir) if !retain
  end

  # Generate hierarchy of text files
  # script : a hash of string(filename) => string(text file contents) or hash (subdirectory)
  #
  def generate_files(base_dir,script,mtime=nil)

    base_dir ||= Dir.pwd

    script.each_pair do |filename,value|
      path = File.join(base_dir,filename)
      if value.instance_of? Hash
        FileUtils.mkdir_p(path)
        if mtime
          File.utime(mtime,mtime,path)
        end
        generate_files(path,value,mtime)
      else
        FileUtils.write_text_file(path,value)
        if mtime
          File.utime(mtime,mtime,path)
        end
      end
    end
  end

  # Redirect stdout to a string buffer
  #
  def redirect_stdout
    raise IllegalStateException, "Already redirected" if @saved_stdout
    @saved_stdout = $stdout
    $stdout = StringIO.new
  end

  # Restore stdout, if it was previously redirected; return
  # the text that was redirected, or nil if it wasn't redirected
  #
  def restore_stdout
    content = nil
    if @saved_stdout
      @saved_stdout.flush
      content = $stdout.string
      $stdout = @saved_stdout
      @saved_stdout = nil
    end
    content
  end

end
