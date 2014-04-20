require 'js_base/js_test'
require 'js_base/pretty'

class TestPretty < JSTest

  def test_pretty_print
    dict = {"a" => 12, "b" => [1,2,3,4], "c" => {"i" => 1, "ii" => 2, "iii" => 3}}
    array = ['January','February',dict,'April']

    TestSnapshot.new.perform do
      puts Pretty.print(array)
    end
  end

  def test_pretty_print_with_sets
    dict = {"a" => 12, "b" => [1,2,3,4], "c" => {"i" => 1, "ii" => 2, "iii" => 3},
            "d" => Set.new([3,1,4,1,5,9,2,7,"alpha","beta"])}
    array = ['January','February',dict,'April']

    TestSnapshot.new.perform do
      puts Pretty.print(array)
    end
  end

end
