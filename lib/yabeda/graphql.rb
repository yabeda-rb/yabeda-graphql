require "yabeda"
require "yabeda/graphql/version"
require "yabeda/graphql/tracing"

module Yabeda
  module GraphQL
    class Error < StandardError; end

    REQUEST_BUCKETS = [
      0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10,
    ].freeze

    Yabeda.configure do
      group :graphql

      histogram :field_resolve_runtime, comment: "A histogram of field resolving time",
                unit: :seconds, per: :field,
                tags: %i[type field deprecated],
                buckets: REQUEST_BUCKETS

      counter :fields_request_count, comment: "A counter for specific fields requests",
              tags: %i[type field deprecated]

      histogram :query_resolve_runtime, comment: "A histogram of query root field resolving time (not whole queries)",
                unit: :seconds, per: :field,
                tags: %i[name deprecated],
                buckets: REQUEST_BUCKETS

      counter :query_count, comment: "A counter for query root fields",
              tags: %i[name deprecated]

      histogram :mutation_resolve_runtime, comment: "A histogram of mutation root field resolving time",
                unit: :seconds, per: :field,
                tags: %i[name deprecated],
                buckets: REQUEST_BUCKETS

      counter :mutation_count, comment: "A counter for mutation root fields",
              tags: %i[name deprecated]
    end
  end
end
