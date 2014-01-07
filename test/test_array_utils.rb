#!/usr/bin/env ruby

require 'js_base/test'

class TestArrayUtils <  Test::Unit::TestCase

  def result(array)
    array.binary_search{|x| x >= 5}
  end

  def test_middle_odd
    assert_equal(result([1,2,5,8,10]),2)
  end

  def test_middle_even
    assert_equal(result([1,2,5,8,10,20]),2)
  end

  def test_first
    assert_equal(result([5,12,20,30,40]),0)
  end

  def test_last_odd
    assert_equal(result([1,2,3,4,5]),4)
  end

  def test_last_even
    assert_equal(result([0,1,2,3,4,5]),5)
  end

  def test_empty
    assert_equal(result([]), 0)
  end

  def test_absent_less
    assert_equal(result([2,3,4]),3)
  end

  def test_absent_greater
    assert_equal(result([10,15,20]),0)
  end

  def test_absent_middle
    assert_equal(result([2,4,8,16,32]),2)
  end

  def test_multiple_answers
    assert_equal(result([0,1,2,3,4,5,5,5,5,5,5,5]),5)
  end

  def test_multiple_answers_2
    assert_equal(result([0,1,2,3,4,5,5,5,5,5,5,5,6,7,8,9]),5)
  end

  def test_large_array
    a = []
    1000.times{|i| a << i-200}
    assert_equal(a.at(result(a)),5)
  end

end

