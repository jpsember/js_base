#!/usr/bin/env ruby

require 'js_base/test'
require 'js_base/pretty'

class TestPretty <  Test::Unit::TestCase

  def test_pretty_print
    dict = {"a" => 12, "b" => [1,2,3,4], "c" => {"i" => 1, "ii" => 2, "iii" => 3}}
    array = ['January','February',dict,'April']

    IORecorder.new.perform do
      puts Pretty.print(array)
    end
  end

end
