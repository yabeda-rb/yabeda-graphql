RSpec.describe Yabeda::GraphQL do
  it "has a version number" do
    expect(Yabeda::GraphQL::VERSION).not_to be nil
  end

  subject do
    YabedaSchema.execute(
      query: query,
      context: {},
      variables: {},
    )
  end

  describe "queries" do
    let(:query) do
      <<~GRAPHQL
        query getProductsAndUsers {
          products {
            id title shmitle price { amount currency }
          }
          users {
            id name
          }
        }
      GRAPHQL
    end

    it "measures field executions" do
      Yabeda.graphql.field_resolve_runtime.sums.clear # This is a hack
      subject
      expect(Yabeda.graphql.field_resolve_runtime.sums).to match(
        { type: "Product", field: "id",       deprecated: false } => kind_of(Numeric),
        { type: "Product", field: "title",    deprecated: false } => be > 0.002,
        { type: "Product", field: "shmitle",  deprecated: true  } => kind_of(Numeric),
        { type: "Product", field: "price",    deprecated: false } => be > 0.01,
        { type: "Price",   field: "amount",   deprecated: false } => kind_of(Numeric),
        { type: "Price",   field: "currency", deprecated: false } => kind_of(Numeric),
        { type: "User",    field: "id",       deprecated: false } => kind_of(Numeric),
        { type: "User",    field: "name",     deprecated: false } => kind_of(Numeric),
      )
    end

    it "measures operation executions" do
      Yabeda.graphql.operation_resolve_runtime.sums.clear # This is a hack
      subject
      expect(Yabeda.graphql.operation_resolve_runtime.sums).to match(
        { operation: "getProductsAndUsers", deprecated: false } => kind_of(Numeric),
        { operation: "getProductsAndUsers", deprecated: true } => kind_of(Numeric),
      )
    end

    it "increment counters" do
      Yabeda.graphql.fields_request_count.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.fields_request_count.values).to match(

        { type: "Product", field: "id",       deprecated: false } => 2,
        { type: "Product", field: "title",    deprecated: false } => 2,
        { type: "Product", field: "shmitle",  deprecated: true  } => 2,
        { type: "Product", field: "price",    deprecated: false } => 2,
        { type: "Price",   field: "amount",   deprecated: false } => 2,
        { type: "Price",   field: "currency", deprecated: false } => 2,
        { type: "User",    field: "id",       deprecated: false } => 1,
        { type: "User",    field: "name",     deprecated: false } => 1,
      )
    end

    it "counts query executions" do
      Yabeda.graphql.query_fields_count.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.query_fields_count.values).to match(
        { name: "products", deprecated: false } => 1,
        { name: "users", deprecated: false } => 1,
      )
    end
  end

  describe "mutations" do
    let(:query) do
      <<~GRAPHQL
        mutation {
          createProduct(input: { title: "Boo" }) {
            product { id title }
          }
        }
      GRAPHQL
    end

    it "measures response field executions" do
      Yabeda.graphql.field_resolve_runtime.sums.clear # This is a hack
      subject
      expect(Yabeda.graphql.field_resolve_runtime.sums).to match(
        { type: "Product",       field: "id",      deprecated: false } => kind_of(Numeric),
        { type: "Product",       field: "title",   deprecated: false } => kind_of(Numeric),
        { type: "CreateProduct", field: "product", deprecated: false } => kind_of(Numeric),
      )
    end

    it "counts mutation executions" do
      Yabeda.graphql.mutation_fields_count.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.mutation_fields_count.values).to match(
        { name: "createProduct", deprecated: false } => 1,
      )
    end
  end
end
