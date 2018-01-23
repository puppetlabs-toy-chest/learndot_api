require 'graphql/client'
require 'graphql/client/http'
require 'json'
require 'logger'

# Configure GraphQL endpoint using the basic HTTP network adapter.
HTTP = GraphQL::Client::HTTP.new("https://api.learndot.io/graphql/") do
  def headers(context)
    {
      "X-API-KEY" => "<token>"
    }
  end
end

# DO NOT regularly get the schema from the API
# There is a bug on line 10211, part of the PriceInput object; you have to remove the amount's default value.
# Otherwise, the schema will fail the graphql-client validation
# GraphQL::Client.dump_schema(HTTP, "schema.json")

SCHEMA = GraphQL::Client.load_schema('schema.json')

Client = GraphQL::Client.new(
  schema: SCHEMA,
  execute: HTTP
)

# Query = Client.parse <<-'GRAPHQL'
#   {
#     contactByLdeId( ldeId: <int> ) {
#       firstName
#       lastName
#     }
#   }
# GRAPHQL

# Learning Component queries only return ELearning Component types
# Query = Client.parse <<-'GRAPHQL'
#   {
#     learningComponentByLdeId( ldeId: <int> ) {
#       displayName
#       description
#     }
#   }
# GRAPHQL

Query = Client.parse <<-'GRAPHQL'
  { 
    allLearningComponents { 
      learningComponents { 
        __typename
      } 
    } 
  }
GRAPHQL

response = Client.query(Query)

puts response.data.to_h