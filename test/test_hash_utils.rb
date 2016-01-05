require 'js_base/js_test'

class TestHashUtils < JSTest

  def test_store_or_delete
    h = {}
    h['a'] = 42
    h['b'] = 77
    h.store_or_delete('b',99)
    assert_equal(99,h['b'])
    h.store_or_delete('b',nil)
    assert(!h.include?('b'))
  end

end

