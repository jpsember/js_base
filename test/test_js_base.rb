#!/usr/bin/env ruby

require 'js_base/test'

class TestJSBase <  Test::Unit::TestCase

  def setup
    enter_test_directory
    @swizzler = Swizzler.new
  end

  def teardown
    @swizzler.remove_all
    leave_test_directory
  end

  def test_run_cmds
    cmds =<<-eos
      pwd
      mkdir alpha
      cd alpha

      # This is a comment
      echo "Howdy" > bravo.txt
      cat bravo.txt

      cd ..
      rm -rf alpha
    eos
    scalls(cmds)
  end

  def test_run_cmds_with_failure
    cmds =<<-eos
      pwd
      mkdir alpha
      cd alpha

      # This is a comment
      echo "Howdy" > bravo.txt
      cat charlie.txt

      cd ..
      rm -rf alpha
    eos

    assert_raise SystemCallException do
      scalls(cmds)
    end
  end

  def test_get_chars_with_interrupt
    interrupted = false
    IORecorder.new.perform do
      puts
      puts "Enter some characters, and stop with ctrl-c"
      begin
        while true
          q = RubyBase.get_user_char
          puts " You typed: '#{q}'"
        end
      rescue Interrupt
        interrupted = true
      end
    end
    assert(interrupted)
  end

  def test_get_chars_without_interrupt
    IORecorder.new.perform do
      puts
      puts "Enter some characters, and stop with 'q'; type ctrl-c one or more times"
      while true
        q = RubyBase.get_user_char('?')
        break if q == 'q'
        puts " You typed: '#{q}'"
      end
    end
  end

  def test_assertions
    @swizzler.add(nil,'die') do |message|
      puts "...ignoring die(#{message})..."
    end

    # Reset the global flag that indicates whether assertion warnings have been given.
    $assertions_found = false

    IORecorder.new.perform do
      puts
      10.times do |x|
        puts "x=#{x}"

        assert!(x != 3, "aborting, #{x} is equal to 3")

        # Test assertion with no arguments
        assert!(x != 8)
      end
    end
  end

  def test_assertions_exit
    @swizzler.add('Kernel','exit') do |code|
      puts "...ignoring exit(#{code})..."
    end

    # Reset the global flag that indicates whether assertion warnings have been given.
    $assertions_found = false

    IORecorder.new.perform do
      puts
      10.times do |x|
        puts "x=#{x}"

        assert!(x != 3, "aborting, #{x} is equal to 3")

        # Test assertion with no arguments
        assert!(x != 8)
      end
    end
  end

  def test_warnings
    IORecorder.new.perform do
      puts
      puts "Some warnings and unimplemented messages"
      3.times do
        puts
        puts "another pass..."
        warning "This is a warning"
        unimp "This is an unimplemented message"
      end
    end
  end

end

