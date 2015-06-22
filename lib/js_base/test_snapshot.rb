# TestSnapshot class
#
# Uses IOCapture class to capture user input and program output,
# and to save these as testing snapshots, or report errors if existing
# snapshots exist and are different.
#

require 'stringio'
require 'tempfile'
require 'js_base/swizzler'
require 'js_base/io_capture'

# Exception class for snapshot disagreeing with reference version
#
class TestSnapshotException < Exception; end

class TestSnapshot

  attr_reader :user_input_path, :output_path

  def initialize(path_prefix = nil)
    @iocapture = nil

    # Look for a calling method that starts with 'test_' prefix
    caller_loc = caller_locations(0)
    index = 0
    while true
      if index >= caller_loc.size
        raise Exception,"Must supply a path prefix"
      end

      caller_method = caller_loc[index]
      this_path_prefix = caller_method.label
      break if this_path_prefix.start_with?('test_')
      index += 1
    end

    # Determine script containing caller method
    caller_path = caller_method.absolute_path
    caller_file = File.basename(caller_path,'.rb')

    if !path_prefix
      path_prefix = this_path_prefix
    end
    @path_prefix = path_prefix

    @snapshot_basename = "_snapshots_[#{caller_file}]_"
    @snapshot_subdir = File.join(File.dirname(caller_path),@snapshot_basename)
  end

  def perform(replace_existing_snapshot=false, &block)
    @replace_existing_snapshot = replace_existing_snapshot
    setup
    completed = false
    begin
      yield
      completed = true
    ensure
      teardown(completed)
    end
  end


  private


  def set_input_script
    # If an input script file exists, read its contents; otherwise, assume empty string.
    # We can thus avoid writing a lot of empty input files.
    input_script = FileUtils.read_text_file(@user_input_path,'')
    @iocapture.set_playback(input_script)
  end


  def setup
    calculate_paths()
    @recording = @replace_existing_snapshot || !File.exist?(@reference_path)

    @iocapture = IOCapture.new

    if !@recording
      @iocapture.echo = false
      set_input_script
    else
      # If we're recording, make sure we echo all input and output to the screen
      @iocapture.echo = true
    end

    @iocapture.open

    # Replace the method that prints filenames and linenumbers with something less sensitive
    # to source file changes (so that warnings that have moved slightly don't cause snapshot errors)
    @swizzler = Swizzler.new
    @swizzler.add_meta('RubyBase','get_filename_linenumber_description'){|f,l| "#{f} (XXX)"}
  end

  def teardown(completed)
    @swizzler.remove_all

    @iocapture.close

    if completed

      if @recording

        # If input is nonempty, write it
        input_script = @iocapture.input_content
        if input_script.length != 0
          FileUtils.write_text_file(@user_input_path,input_script)
        end

        # Write output

        output_content = @iocapture.output_content

        # Print warning if existing snapshot changed
        if @replace_existing_snapshot
          existing = FileUtils.read_text_file(@reference_path)
          if (existing && output_content != existing)
            puts "...snapshot changed: #{@reference_path}"
          end
        end

        FileUtils.write_text_file(@reference_path,output_content)

      else

        # Not implemented: verify that we used the entire input script

        @snapshot_path = Tempfile.new('io_recorder').path
        FileUtils.write_text_file(@snapshot_path,@iocapture.output_content)
        compare_reference_and_snapshot
      end
    else
      puts "\n(Failed to complete TestSnapshot task: #{@path_prefix})"
    end
  end

  def calculate_paths
    # If no _snapshot_ subdirectory exists, create it
    Dir.mkdir(@snapshot_subdir) if !File.directory?(@snapshot_subdir)
    @user_input_path = File.join(@snapshot_subdir,@path_prefix + '_input.txt')
    @reference_path = File.join(@snapshot_subdir,@path_prefix + '_reference.txt')
  end


  def compare_reference_and_snapshot(assert_if_mismatch = true)
    difference = calc_diff(@reference_path,nil,@snapshot_path,nil)
    if assert_if_mismatch
      if difference
        lines = "\n" + ('-' * 130) + "\n"
        raise TestSnapshotException,"Output does not match reference file #{@snapshot_basename}/#{@path_prefix}:" \
        + lines + difference.chomp + lines
      end
    end
    difference == nil
  end

  def calc_diff(path1=nil, text1=nil, path2=nil, text2=nil)
    path1 = write_if_nec(path1,text1)
    path2 = write_if_nec(path2,text2)
    df,_ = scall("diff -C 1 \"#{path1}\" \"#{path2}\"", false)
    df = nil if df.size == 0

    if df
     df,_ = scall("diff --width=130 -y \"#{path1}\" \"#{path2}\"", false)
    end
    df
  end

  # Write text to a temporary file, and return path to that file
  #
  def write_to_temp(text)
    file = Tempfile.new('_rubytools_')
    path = file.path
    write_text_file(path,text)
    path
  end

  def write_if_nec(path,text)
    if !path
      raise Exception,"missing text" if !text
      path = write_to_temp(text)
    end
    path
  end

end
