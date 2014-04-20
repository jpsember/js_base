# Used by IOCapture class
#
require 'stringio'

class IOInputCapture

  attr_accessor :buffer

  def initialize
    self.buffer = StringIO.new
    @actual_stdin = $stdin
    @playback_text = nil
    @playback_cursor = 0
  end

  def set_playback(text)
    @playback_text = text
    @playback_cursor = 0
  end

  def gets
    if @playback_text
      x = ''
      while true
        ch = self.getch
        x << ch
        break if ch == "\n"
      end
    else
      x = @actual_stdin.gets
    end
    self.buffer.write(x)
    $stdout.write(x)
    x
  end

  def flush
  end

  def getch
    if @playback_text
      if @playback_cursor == @playback_text.length
        die "End of input playing back IOInputCapture"
      end
      x = @playback_text[@playback_cursor]
      @playback_cursor += 1
    else
      x = getch_from_actual
    end
    self.buffer.write(x)
    x
  end

  # Exposed for unit testing:
  def getch_from_actual
    @actual_stdin.getch
  end

end
