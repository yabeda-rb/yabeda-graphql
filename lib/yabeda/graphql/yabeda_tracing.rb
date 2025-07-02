module Yabeda
  module GraphQL
    module YabedaTracing
      def execute_field(field:, query:, ast_node:, arguments:, object:, &block)
        start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
        result = block.call
        duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start

        tags = extract_field_tags(field)
        path = query.context.current_path

        if path.length == 1
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

    end
  end
end
