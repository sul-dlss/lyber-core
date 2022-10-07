# frozen_string_literal: true

require 'stringio'

# capture stdout so that we can assert expectations on it
def capture_stdout
  old = $stdout
  $stdout = fake = StringIO.new
  yield
  fake.string
ensure
  $stdout = old
end
