#!/usr/bin/env ruby

require 'test/unit'
require 'js_base'
require 'js_base/io_recorder'

class TestIORecorder < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def snapshot_path
  end

  def test_io_recorder

    inp_path = nil

    rec = IORecorder.new
    rec.perform do
      inp_path = rec.user_input_path

      puts "\nThis is a test of the IORecorder class."
      printf("Hello, type something:")
      z = $stdin.gets.chomp!
      printf("...'%s'\n",z)

      printf("Calling $stdout.putc: ")
      $stdout.putc(65)
      $stdout.putc('a')
      puts

      printf("Calling $stdout.printf: ")
      $stdout.printf("Here is an integer: %d",72)
      $stdout.printf("\n")

      while true
        printf("Type any key (q to quit):")
        z = RubyBase.get_user_char
        printf("...(%s)\n",z)
        break if z == 'q'
      end

      puts [1,2,33,23]

      puts "This concludes the test.\n"
    end
    assert(File.file?(inp_path))
  end


  def test_io_recorder_no_input

    inp_path = nil

    rec = IORecorder.new
    rec.perform do
      inp_path = rec.user_input_path

      puts "\nThis is a test of the IORecorder class."

      printf("Calling $stdout.putc: ")
      $stdout.putc(65)
      $stdout.putc('a')
      puts

      printf("Calling $stdout.printf: ")
      $stdout.printf("Here is an integer: %d",72)
      $stdout.printf("\n")

      puts [1,2,33,23]

      puts "This concludes the test.\n"

    end

    assert(!File.file?(inp_path))
  end


end
