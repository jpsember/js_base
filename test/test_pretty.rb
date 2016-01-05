require 'js_base/js_test'

class TestPretty < JSTest

  def test_pretty_print
    dict = {"a" => 12, "b" => [1,2,3,4], "c" => {"i" => 1, "ii" => 2, "iii" => 3}}
    array = ['January','February',dict,'April']

    TestSnapshot.new.perform do
      puts pretty_pr(array)
    end
  end

  def test_pretty_print_long_keys
    dict2 = {"abc" => 14, "def" => 22}
    dict1 = {"aaaa_aaaa_aaaa_aaaa_aaaa" => 12,
             "b" => [1,2,3,4],
             "cccc_cccc_cccc_cccc_cccc_cccc" => {"i" => 1,
                                                 "ii" => 2,
                                                 "dict2" => dict2,
                                                 "iii" => 3}}
    array = ['January','February',dict1,'April']

    TestSnapshot.new.perform do
      puts pretty_pr(array)
    end
  end


end
