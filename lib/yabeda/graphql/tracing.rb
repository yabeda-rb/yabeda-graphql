require "graphql/tracing/platform_tracing"

module Yabeda
  module GraphQL
    class Tracing < ::GraphQL::Tracing::PlatformTracing

      self.platform_keys = {
          'lex' => "graphql.lex",
          'parse' => "graphql.parse",
          'validate' => "graphql.validate",
          'analyze_query' => "graphql.analyze",
          'analyze_multiplex' => "graphql.analyze",
          'execute_multiplex' => "graphql.execute",
          'execute_query' => "graphql.execute",
          'execute_query_lazy' => "graphql.execute",
          'execute_field' => "graphql.execute",
          'execute_field_lazy' => "graphql.execute"
      }

      def platform_trace(platform_key, key, data, &block)
        start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
        result = block.call
        duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start

        case key
        when "execute_field", "execute_field_lazy"
          field, path, query = extract_field_trace_data(data)

          tags = extract_field_tags(field)
          if path.length == 1
            if query.query?
              instrument_query_execution(tags)
            elsif query.mutation?
              instrument_mutation_execution(tags)
            elsif query.subscription?
              # Not implemented yet
            end
          else
            instrument_field_execution(tags, duration)
          end
        end

        result
      end

      # See https://graphql-ruby.org/api-doc/1.10.5/GraphQL/Tracing
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

      def instrument_field_execution(tags, duration)
        Yabeda.graphql.field_resolve_runtime.measure(tags, duration)
        Yabeda.graphql.fields_request_count.increment(tags)
      end

      def instrument_mutation_execution(tags)
        tags = { name: tags[:field], deprecated: tags[:deprecated] }
        Yabeda.graphql.mutation_fields_count.increment(tags)
      end

      def instrument_query_execution(tags)
        tags = { name: tags[:field], deprecated: tags[:deprecated] }
        Yabeda.graphql.query_fields_count.increment(tags)
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
