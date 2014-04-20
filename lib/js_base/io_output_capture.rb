# Used by IOCapture class
#
require 'stringio'

class IOOutputCapture < StringIO

  attr_accessor :echo, :content_buffer

  DASHES = ('-' * 130)

  def initialize(echo, content_buffer, channel_flag, for_errors)
    self.echo = echo
    self.content_buffer = content_buffer
    @channel_flag = channel_flag
    @for_errors = for_errors
    @actual_output = for_errors ? $stderr : $stdout
  end

  def print_interleave_transition
    if @for_errors != @channel_flag[0]
      msg = ''
      msg << "\n" if !self.content_buffer.string.end_with?("\n")
      msg << '-'*30
      msg << (@for_errors ? '<stderr>' : '<stdout>')
      msg << '-'*30
      msg << "\n"
      @actual_output.write(msg) if self.echo
      self.content_buffer.write(msg)
      @channel_flag[0] = @for_errors
    end
  end

  def putc(value)
    print_interleave_transition
    @actual_output.putc(value) if self.echo
    self.content_buffer.putc(value)
  end

  def write(str)
    print_interleave_transition
    @actual_output.write(str) if self.echo
    self.content_buffer.write(str)
  end

  def flush
    self.content_buffer.flush
  end

  def close
    self.flush
  end

  def string
    self.content_buffer.string
  end

  def tty?
    false
  end

end
