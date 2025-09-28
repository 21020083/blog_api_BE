RSpec::Matchers.define :complete_within do |expected_time|
  match do |block|
    start_time = Time.current
    block.call
    end_time = Time.current
    @actual_time = end_time - start_time
    @actual_time <= expected_time
  end

  failure_message do |block|
    "expected block to complete within #{expected_time} seconds, but took #{@actual_time} seconds"
  end

  failure_message_when_negated do |block|
    "expected block to not complete within #{expected_time} seconds, but took #{@actual_time} seconds"
  end

  description do
    "complete within #{expected_time} seconds"
  end
end
