require 'js_base/js_test'

class TestSCall < JSTest

  def test_scall_capture_call_nonexistent_program
    result,success = scall('fooxyz arg1 arg2', false)
    assert(!success)
  end

end
