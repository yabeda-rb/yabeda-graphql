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
        query {
          products {
            id title shmitle price { amount currency } 
          }
        }
      GRAPHQL
    end

    it "measures field executions" do
      Yabeda.graphql.field_resolve_runtime.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.field_resolve_runtime.values).to match(
        { type: "Product", field: "id",       deprecated: false } => kind_of(Numeric),
        { type: "Product", field: "title",    deprecated: false } => kind_of(Numeric),
        { type: "Product", field: "shmitle",  deprecated: true  } => kind_of(Numeric),
        { type: "Product", field: "price",    deprecated: false } => kind_of(Numeric),
        { type: "Price",   field: "amount",   deprecated: false } => kind_of(Numeric),
        { type: "Price",   field: "currency", deprecated: false } => kind_of(Numeric),
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
      )
    end

    it "measures query execution time" do
      Yabeda.graphql.query_resolve_runtime.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.query_resolve_runtime.values).to match(
        { name: "products", deprecated: false } => kind_of(Numeric),
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

    it "measures field executions" do
      Yabeda.graphql.field_resolve_runtime.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.field_resolve_runtime.values).to match(
        { type: "Product", field: "id",       deprecated: false } => kind_of(Numeric),
        { type: "Product", field: "title",    deprecated: false } => kind_of(Numeric),
        { type: "CreateProductPayload", field: "product", deprecated: false } => kind_of(Numeric),
      )
    end

    it "measures mutation execution time" do
      Yabeda.graphql.mutation_resolve_runtime.values.clear # This is a hack
      subject
      expect(Yabeda.graphql.mutation_resolve_runtime.values).to match(
        { name: "createProduct", deprecated: false } => kind_of(Numeric),
      )
    end
  end
end
