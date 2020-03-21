# frozen_string_literal: true
require "graphql"
require "graphql/batch"

class PriceLoader < GraphQL::Batch::Loader
  def perform(ids)
    sleep 0.01
    ids.each { |id| fulfill(id, { currency: "USD", amount: 1.0 }) }
  end
end

class PriceType < GraphQL::Schema::Object
  field :currency, String, null: false, hash_key: :currency
  field :amount,   Float,  null: false, hash_key: :amount
end

class ProductType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :title, String, null: true
  field :shmitle, String, null: true, method: :title, deprecation_reason: "Just shit"
  field :price, PriceType,  null: true

  def price
    PriceLoader.load(object.id)
  end
end

class UserType < GraphQL::Schema::Object
  field :id, ID, null: false
  field :name, String, null: true
end

class Product < OpenStruct
  def title
    sleep 0.001
    super
  end
end

class User < OpenStruct
  def name
    super
  end
end

class QueryType < GraphQL::Schema::Object
  field :products, [ProductType], null: false
  field :users, [UserType], null: false

  def products
    [
      Product.new(id: 1, title: "Foo", price: { currency: "USD", amount: 1.0 }),
      Product.new(id: 2, title: "Foo", price: { currency: "RUB", amount: 75.0 }),
    ]
  end

  def users
    [User.new(id: 1, name: "Andrey")]
  end
end

class CreateProduct < GraphQL::Schema::RelayClassicMutation
  argument :title, String, required: true

  field :product, ProductType, null: true
  field :errors, [String], null: false

  def resolve(title:)
    { product: { id: 42, title: title } }
  end
end


class MutationType < GraphQL::Schema::Object
  field :create_product, mutation: CreateProduct
end

class SubscriptionType < GraphQL::Schema::Object
  field :product_created, ProductType, null: false
  field :product_updated, ProductType, null: false

  # See https://github.com/rmosolgo/graphql-ruby/issues/1567
  def product_created; end
  def product_updated; end
end

class YabedaSchema < GraphQL::Schema
  use Yabeda::GraphQL

  if TESTING_GRAPHQL_RUBY_INTERPRETER
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
  end

  query QueryType
  mutation MutationType
  subscription SubscriptionType

  use GraphQL::Batch
end
