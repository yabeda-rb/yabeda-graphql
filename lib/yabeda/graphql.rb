require "graphql/version"
require "yabeda"
require "yabeda/graphql/version"
require "yabeda/graphql/yabeda_tracing"
require "yabeda/graphql/instrumentation"
require "yabeda/graphql/legacy/yabeda_tracing"
require "yabeda/graphql/legacy/instrumentation"

module Yabeda
  module GraphQL
    class Error < StandardError; end

    REQUEST_BUCKETS = [
      0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10,
    ].freeze

    Yabeda.configure do
      group :graphql

      histogram :field_resolve_runtime, comment: "A histogram of field resolving time",
                unit: :seconds, per: :field,
                tags: %i[type field deprecated],
                buckets: REQUEST_BUCKETS

      counter :fields_request_count, comment: "A counter for specific fields requests",
              tags: %i[type field deprecated]

      counter :query_fields_count, comment: "A counter for query root fields",
              tags: %i[name deprecated]

      counter :mutation_fields_count, comment: "A counter for mutation root fields",
              tags: %i[name deprecated]
    end

    def self.use(schema)
      if Gem::Version.new(::GraphQL::VERSION) >= Gem::Version.new( "2.2.0")
        schema.trace_with Yabeda::GraphQL::Instrumentation
        schema.trace_with Yabeda::GraphQL::YabedaTracing
      else
        schema.instrument :query, Legacy::Instrumentation.new
        schema.use Legacy::YabedaTracing, trace_scalars: true
      end
    end
  end
end
