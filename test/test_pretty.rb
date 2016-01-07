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
    TestSnapshot.new.perform do
      puts pretty_pr(dict1)
    end
  end

  def test_padding_occurs
    dict2 = {"abc" => 14, "def" => 22}
    dict1 = {"0123456789012345" => "padding allowed, values shifted by padding",
             "01234567890123456" => 12,
             "012345678901234567" => 12,
             "0123456789012345678" => 12,
             "01234567890123456789" => 12,
             "012345678901234567890" => dict2,
             "01334567890123456789" => 10
           }
    TestSnapshot.new.perform do
      puts pretty_pr(dict1)
    end
  end

  def test_no_padding_occurs
    dict2 = {"abc" => 14, "def" => 22}
    dict1 = {"0123456789012345" => "no padding allowed",
             "01234567890123456" => 12,
             "012345678901234567" => 12,
             "0123456789012345678" => 12,
             "01234567890123456789" => 12,
             "012345678901234567890" => 12,
             "0123456789012345678901" => dict2,
             "01234567890123456789012" => 12,
             "01334567890123456789" => 10
           }
    TestSnapshot.new.perform do
      puts pretty_pr(dict1)
    end
  end

end
