# frozen_string_literal: true
require "graphql"

class Price < GraphQL::Schema::Object
  field :currency, String, null: false, hash_key: :currency
  field :amount,   Float,  null: false, hash_key: :amount
end

class Product < GraphQL::Schema::Object
  field :id, ID, null: false, hash_key: :id
  field :title, String, null: true, hash_key: :title
  field :shmitle, String, null: true, hash_key: :title, deprecation_reason: "Just shit"
  field :price, Price,  null: true, hash_key: :price
end

class QueryType < GraphQL::Schema::Object
  field :products, [Product], null: false

  def products
    [
      { id: 1, title: "Foo", price: { currency: "USD", amount: 1.0 } },
      { id: 2, title: "Foo", price: { currency: "RUB", amount: 75.0 } },
    ]
  end
end

class CreateProduct < GraphQL::Schema::RelayClassicMutation
  argument :title, String, required: true

  field :product, Product, null: true
  field :errors, [String], null: false

  def resolve(title:)
    { product: { id: 42, title: title } }
  end
end


class MutationType < GraphQL::Schema::Object
  field :create_product, mutation: CreateProduct
end

class SubscriptionType < GraphQL::Schema::Object
  field :product_created, Product, null: false
  field :product_updated, Product, null: false

  # See https://github.com/rmosolgo/graphql-ruby/issues/1567
  def product_created; end
  def product_updated; end
end

class YabedaSchema < GraphQL::Schema
  use Yabeda::GraphQL::Tracing, trace_scalars: true

  if TESTING_GRAPHQL_RUBY_INTERPRETER
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
  end

  query QueryType
  mutation MutationType
  subscription SubscriptionType
end
