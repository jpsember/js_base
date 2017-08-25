require 'js_base/js_test'

class TestJSBase < JSTest

  def test_run_cmds
    enter_test_directory
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
    enter_test_directory
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

    assert_raises SystemCallException do
      scalls(cmds)
    end
  end

  def test_get_chars_with_interrupt
    interrupted = false
    TestSnapshot.new.perform do
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
    TestSnapshot.new.perform do
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
    self.swizzler.add(nil,'die') do |message|
      puts "...ignoring die(#{message})..."
    end

    # Reset the global flag that indicates whether assertion warnings have been given.
    $assertions_found = false

    TestSnapshot.new.perform do
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
    self.swizzler.add('Kernel','exit') do |code|
      puts "...ignoring exit(#{code})..."
    end

    # Reset the global flag that indicates whether assertion warnings have been given.
    $assertions_found = false

    TestSnapshot.new.perform do
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
    TestSnapshot.new.perform do
      puts
      puts "Some warnings and unimplemented messages"
      3.times do
        puts
        puts "another pass..."
        warning "This is a warning"
        unimp "This is an unimplemented message"
        warning ' %s Should not be treated as sprintf argument'
        warning ' %s be treated as sprintf argument', "Should"
      end
    end
  end

  def test_from_our_dir
    original_dir = Dir.pwd
    require_relative 'subdir/misc'
    misc_test_from_our_dir
    assert_equal(Dir.pwd,original_dir)
  end

end

