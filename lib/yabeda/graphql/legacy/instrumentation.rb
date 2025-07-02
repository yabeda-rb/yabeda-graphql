module Yabeda
  module GraphQL
    module Legacy
      class Instrumentation
        def before_query(query)
          reset_cache!(query)
        end

        def after_query(query)
          cache(query).each do |_path, options|
            Yabeda.graphql.field_resolve_runtime.measure(options[:tags], options[:duration])
            Yabeda.graphql.fields_request_count.increment(options[:tags])
          end
        end

        private

        def cache(query)
          query.context.namespace(Yabeda::GraphQL)[:field_call_cache]
        end

        def reset_cache!(query)
          query.context.namespace(Yabeda::GraphQL)[:field_call_cache] =
            Hash.new { |h,k| h[k] = { tags: {}, duration: 0.0 } }
        end
      end
    end
  end
end
