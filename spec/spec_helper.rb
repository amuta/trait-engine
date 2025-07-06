# frozen_string_literal: true

require "bundler/setup"
require "kumi"
require "pry"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
