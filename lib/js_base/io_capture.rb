require 'stringio'
require 'js_base/io_output_capture'
require 'js_base/io_input_capture'

class IOCapture

  attr_accessor :echo

  # This is where the captured output will be written to
  attr_accessor :content_buffer

  attr_accessor :is_open

  def initialize
    self.echo = false
    self.content_buffer = StringIO.new
    self.is_open = false
    @playback_script = nil
  end

  def set_playback(text)
    die("already open") if self.is_open
    @playback_script = text
  end

  def open
    die("already open") if self.is_open
    self.is_open = true
    # Construct substitutes for stdout and stderr, that will write to our content buffer
    our_stderr_flag = [false]
    @my_stdout = IOOutputCapture.new(self.echo,self.content_buffer,our_stderr_flag, false)
    @my_stderr = IOOutputCapture.new(self.echo,self.content_buffer,our_stderr_flag, true)
    @my_input = IOInputCapture.new
    if @playback_script
      @my_input.set_playback(@playback_script)
    end
    @saved_stdout = $stdout
    @saved_stdin = $stdin
    @saved_stderr = $stderr
    $stdout = @my_stdout
    $stderr = @my_stderr
    $stdin = @my_input
  end

  def close
    if (self.is_open)
      $stdout = @saved_stdout
      $stderr = @saved_stderr
      $stdin = @saved_stdin
      @my_stdout.close
      self.is_open = false
    end
  end

  def output_content
    die("IOCapture is still open") if self.is_open
    self.content_buffer.string
  end

  def input_content
    die("IOCapture is still open") if self.is_open
    @my_input.buffer.string
  end

end
