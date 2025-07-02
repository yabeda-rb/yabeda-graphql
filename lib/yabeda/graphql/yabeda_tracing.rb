#require "graphql/tracing/platform_tracing"

module Yabeda
  module GraphQL
    module YabedaTracing
      def execute_field(field:, query:, ast_node:, arguments:, object:, &block)
        start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
        result = block.call
        duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start

        tags = extract_field_tags(field)

        # Create a unique path for each field execution to ensure proper counting
        path = [field.owner.graphql_name, field.graphql_name, object.object_id.to_s]

        # Check if this is a root field by looking at the parent type
        parent_type = field.owner
        is_root_field = [query.schema.query, query.schema.mutation, query.schema.subscription].include?(parent_type)

        if is_root_field
          return result if query.schema.lazy?(result)

          if query.query?
            instrument_query_execution(tags)
          elsif query.mutation?
            instrument_mutation_execution(tags)
          elsif query.subscription?
            # Not implemented yet
          end
        else
          instrument_field_execution(query, path, tags, duration)
        end

        result
      end

      def execute_field_lazy(field:, query:, ast_node:, arguments:, object:, &block)
        execute_field(field: field, query: query, ast_node: ast_node, arguments: arguments, object: object, &block)
      end

      def extract_field_trace_data(data)
        if data[:context] # Legacy non-interpreter mode
          [data[:context].field, data[:context].path, data[:context].query]
        else # Interpreter mode
          data.values_at(:field, :path, :query)
        end
      end

      def extract_field_tags(field)
        owner = field.respond_to?(:owner) ? field.owner : field.metadata[:type_class].owner
        {
          type: owner.graphql_name,
          field: field.graphql_name,
          deprecated: !field.deprecation_reason.nil?,
        }
      end

      def instrument_field_execution(query, path, tags, duration)
        cache(query)[path][:tags] = tags
        cache(query)[path][:duration] += duration
      end

      def instrument_mutation_execution(tags)
        tags = { name: tags[:field], deprecated: tags[:deprecated] }
        Yabeda.graphql.mutation_fields_count.increment(tags)
      end

      def instrument_query_execution(tags)
        tags = { name: tags[:field], deprecated: tags[:deprecated] }
        Yabeda.graphql.query_fields_count.increment(tags)
      end

      def cache(query)
        query.context.namespace(Yabeda::GraphQL)[:field_call_cache]
      end

      def platform_field_key(type, field)
        "#{type.graphql_name}.#{field.graphql_name}"
      end

      # We don't use these yet, but graphql-ruby require us to declare them

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end
    end
  end
end
