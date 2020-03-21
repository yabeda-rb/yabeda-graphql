require "bundler/setup"
require "yabeda/graphql"
require "pry"
require "yaml"

TESTING_GRAPHQL_RUBY_INTERPRETER =
  begin
    env_value = ENV["GRAPHQL_RUBY_INTERPRETER"]
    env_value ? YAML.safe_load(env_value) : false
  end

require_relative "support/graphql_schema"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec

  Kernel.srand config.seed
  config.order = :random

  config.before(:all) do
    Yabeda.configure!
  end
end

# Add sum of all observed values to histograms to check in tests
module SummingHistogram
  def measure(tags, value)
    all_tags = ::Yabeda::Tags.build(tags)
    sums[all_tags] += value
    super
  end

  def sums
    @sums ||= Concurrent::Hash.new { |h, k| h[k] = 0.0 }
  end
end

Yabeda::Histogram.prepend(SummingHistogram)
