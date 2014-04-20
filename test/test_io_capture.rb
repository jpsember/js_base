require 'js_base/js_test'

class TestIOCapture < JSTest

  def test_input_capture

    # Swizzle the RubyBase.get_user_char method to return a particular sequence of characters

    cursor = 0
    script = "abcdeq"

    swizzler = Swizzler.new
    swizzler.add("IOInputCapture","getch_from_actual") do
      h = script[cursor]
      cursor += 1
      h
    end

    cap = IOCapture.new
    cap.open
    puts "Enter a character:\n"

    while true
      printf("Type any key (q to quit):")
      z = RubyBase.get_user_char
      printf("...(%s)\n",z)
      break if z == 'q'
    end

    cap.close

    text = cap.input_content

    swizzler.remove_all
    assert(text == script,"expected captured input '#{text}' to equal '#{script}'")
  end

  def test_input_playback
    script = "abcdeq"

    cap = IOCapture.new
    cap.set_playback(script)

    cap.open
    puts "Enter a character:\n"

    while true
      printf("Type any key (q to quit):")
      z = RubyBase.get_user_char
      printf("...(%s)\n",z)
      break if z == 'q'
    end

    cap.close
    text = cap.input_content
    assert(text == script)
  end


  def test_output_capture

    cap = IOCapture.new
    # cap.echo = true

    cap.open

    puts "\nThis is a test of the IOCapture class."

    printf("Calling $stdout.putc: ")
    $stdout.putc(65)
    $stdout.putc('a')
    puts

    printf("Calling $stdout.printf: ")
    $stdout.printf("Here is an integer: %d",72)
    $stdout.printf("\n")

    puts [1,2,33,23]

    puts "Generating some stderr output:"
    $stderr.printf("There may have been a problem, #%d",42)

    puts "Resuming with stdout"

    puts "This concludes the test.\n"

    cap.close

    text = cap.output_content
    assert(text.length > 20)
  end

end
