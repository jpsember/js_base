#!/usr/bin/env ruby

require 'stringio'
require 'tempfile'
require 'js_base/swizzler'

# Exception class for snapshot disagreeing with reference version
#
class SnapshotException < Exception; end

class IORecorder

  attr_reader :user_input_path, :output_path

  def initialize(path_prefix = nil)
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

  def perform(&block)
    setup()
    completed = false
    begin
      yield
      completed = true
    ensure
      teardown(completed)
    end
  end


  private


  def setup
    calculate_paths()
    @recording = !File.exist?(@reference_path)
    prepare_script_files()

    # Construct substitutes for stdout and stderr that are interleaved within a common StringIO buffer
    our_string_buffer = StringIO.new
    our_stderr_flag = [false]
    @my_stdout = OurOutput.new(@recording, our_string_buffer, our_stderr_flag, false)
    @my_stderr = OurOutput.new(@recording, our_string_buffer, our_stderr_flag, true)
    @my_input = OurInput.new(@recording, @user_input_file)

    @saved_stdout = $stdout
    @saved_stdin = $stdin
    @saved_stderr = $stderr
    $stdout = @my_stdout
    $stderr = @my_stderr
    $stdin = @my_input

    # Replace the method that prints filenames and linenumbers with something less sensitive
    # to source file changes (so that warnings that have moved slightly don't cause snapshot errors)
    @swizzler = Swizzler.new
    @swizzler.add_meta('RubyBase','get_filename_linenumber_description'){|f,l| "#{f} (XXX)"}
  end

  def teardown(completed)
    @swizzler.remove_all

    $stdout = @saved_stdout
    $stderr = @saved_stderr
    $stdin = @saved_stdin
    if completed
      @user_input_file.close
      # If we're recording, and we didn't read any input, delete the file
      if @recording && FileUtils.read_text_file(@user_input_path).length == 0
        FileUtils.rm_rf(@user_input_path)
      end
      @my_stdout.close
      FileUtils.write_text_file(@output_path,@my_stdout.string)
      if !@recording
        compare_reference_and_snapshot()
      end
    end
  end

  def calculate_paths
    # If no _snapshot_ subdirectory exists, create it
    Dir.mkdir(@snapshot_subdir) if !File.directory?(@snapshot_subdir)
    @user_input_path = File.join(@snapshot_subdir,@path_prefix + '_input.txt')
    @reference_path = File.join(@snapshot_subdir,@path_prefix + '_reference.txt')
  end

  def prepare_script_files
    # Only write files if they end up being nonempty
    if @recording
      # User input => user input file
      @user_input_file = File.open(@user_input_path,'w')
      # Console output => reference file
      @output_path = @reference_path
      # @console_file = File.open(@reference_path,'w')
    else
      # User input <= user input file
      @user_input_file = StringIO.new(FileUtils.read_text_file(@user_input_path,''),'r')
      # Console output => snapshot file
      @snapshot_path = Tempfile.new('io_recorder').path
      @output_path = @snapshot_path
    end
  end

  def compare_reference_and_snapshot(assert_if_mismatch = true)
    difference = calc_diff(@reference_path,nil,@snapshot_path,nil)
    if assert_if_mismatch
      if difference
        lines = "\n" + ('-' * 130) + "\n"
        raise SnapshotException,"Output does not match reference file #{@snapshot_basename}/#{@path_prefix}:" \
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


  class OurOutput < StringIO

    DASHES = ('-' * 130)

    def initialize(recording, string_buffer, channel_flag, for_errors)
      @recording = recording
      @string_buffer = string_buffer
      @channel_flag = channel_flag
      @for_errors = for_errors
      @actual_output = for_errors ? $stderr : $stdout
    end

    def print_interleave_transition
      if @for_errors != @channel_flag[0]
        msg = ''
        msg << "\n" if !@string_buffer.string.end_with?("\n")
        msg << '-'*30
        msg << (@for_errors ? '<stderr>' : '<stdout>')
        msg << '-'*30
        msg << "\n"
        @actual_output.write(msg) if @recording
        @string_buffer.write(msg)
        @channel_flag[0] = @for_errors
      end
    end

    def putc(value)
      print_interleave_transition
      @actual_output.putc(value) if @recording
      @string_buffer.putc(value)
    end

    def write(str)
      print_interleave_transition
      @actual_output.write(str) if @recording
      @string_buffer.write(str)
    end

    def flush
      @string_buffer.flush
    end

    def close
      @string_buffer.close
    end

    def string
      @string_buffer.string
    end

    def tty?
      false
    end

  end


  class OurInput

    # @param recording true if recording vs playing back
    # @param user_input_file  if recording, inputs are read from user and written here;
    #   else values are read from here
    #
    def initialize(recording, user_input_file)
      @recording = recording
      @user_input_file = user_input_file
      @actual_stdin = $stdin
    end

    def gets
      if @recording
        x = @actual_stdin.gets
        @user_input_file.write(x)
      else
        x = @user_input_file.gets
        raise SnapshotException,"Out of input" if !x
      end
      $stdout.write(x)
      x
    end

    def flush
    end

    def getc
      if @recording
        x = @actual_stdin.getc
        @user_input_file.write(x)
      else
        x = @user_input_file.getc
        raise SnapshotException,"Out of input" if !x
      end
      $stdout.write(x)
      x
    end

  end

end
