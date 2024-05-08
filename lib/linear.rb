require 'graphlient'

require_relative 'linear_queries'
class Linear
  BASE_URL = 'https://api.linear.app/graphql'.freeze

  def initialize(api_key)
    @api_key = api_key
    raise ArgumentError, 'Missing Credentials' if @api_key.blank?

    @client = Graphlient::Client.new(
      BASE_URL,
      headers: {
        'Authorization' => @api_key,
        'Content-Type' => 'application/json'
      }
    )
  end

  def teams
    execute_query(LinearQueries::TEAMS_QUERY)
  end

  def team_entites(team_id)
    raise ArgumentError, 'Missing team id' if team_id.blank?

    execute_query(LinearQueries.team_entites_query(team_id))
  end

  def create_issue(team_id, title, description)
    raise ArgumentError, 'Missing team id' if team_id.blank?
    raise ArgumentError, 'Missing title' if title.blank?
    raise ArgumentError, 'Missing description' if description.blank?

    execute_mutation(LinearMutations::ISSUE_CREATE, input: { teamId: team_id, title: title, description: description })
  end

  private

  def execute_query(query)
    response = @client.query(query)
    log_and_return_error("Error retrieving data: #{response.errors.messages}") if response.data.nil? && response.errors.any?
    response.data.to_h
  rescue Graphlient::Errors::GraphQLError => e
    log_and_return_error("GraphQL Error: #{e.message}")
  rescue Graphlient::Errors::ServerError => e
    log_and_return_error("Server Error: #{e.message}")
  rescue StandardError => e
    log_and_return_error("Unexpected Error: #{e.message}")
  end

  def execute_mutation(query, variables)
    response = @client.query(query, variables: variables)
    log_and_return_error("Error creating issue: #{response.errors.messages}") if response.data.nil? && response.errors.any?
    response.data.to_h
  end

  def log_and_return_error(message)
    Rails.logger.error message
    { error: message }
  end
end
