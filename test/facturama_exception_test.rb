require "minitest/autorun"
require_relative "../lib/facturama/models/exception/facturama_exception"

# #1338: FacturamaException must inherit from StandardError so a bare `rescue`
# (which only catches StandardError descendants) catches it. Otherwise it
# escapes silently from any consumer that does `rescue => e`.
class FacturamaExceptionTest < Minitest::Test
  def test_instances_are_standard_errors
    assert_kind_of StandardError, FacturamaException.new("boom")
  end

  def test_caught_by_bare_rescue
    rescued = nil
    begin
      begin
        raise FacturamaException.new("boom")
      rescue => e # bare rescue == rescue StandardError
        rescued = e
      end
    rescue Exception
      # swallow so a non-StandardError reports a clean failure, not an error
    end
    assert_instance_of FacturamaException, rescued
  end

  def test_preserves_message_and_details
    error = FacturamaException.new("boom", { code: 42 })
    assert_equal "boom", error.message
    assert_equal({ code: 42 }, error.details)
  end
end
