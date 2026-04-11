# frozen_string_literal: true

require 'singleton'
require 'json'

# Client authorization
module WhatsupGithub
  # Create a singleton object for Client.
  # Authorize with a GitHub token from $WHATSUP_GITHUB_ACCESS_TOKEN if available
  # Otherwise, use credentials from ~/.netrc
  # Otherwise, continue as a Guest
  class Client
    include Singleton

    WHATSUP_GITHUB_ACCESS_TOKEN = ENV['WHATSUP_GITHUB_ACCESS_TOKEN']
    private_constant :WHATSUP_GITHUB_ACCESS_TOKEN

    def initialize
      @client =
        if WHATSUP_GITHUB_ACCESS_TOKEN
          Octokit::Client.new(access_token: WHATSUP_GITHUB_ACCESS_TOKEN)
        elsif File.exist?(File.expand_path('~/.netrc'))
          warn_if_insecure_netrc
          Octokit::Client.new(netrc: true)
        else
          warn 'WARNING: No credentials found. Running unauthenticated (rate limit: 60 req/hour).'
          warn 'Set WHATSUP_GITHUB_ACCESS_TOKEN or configure ~/.netrc to authenticate.'
          Octokit::Client.new
        end
    end

    def search_issues(query)
      @client.search_issues(query)
    end

    def pull_request(repo, number)
      @client.pull_request(repo, number)
    end

    def org_members(org)
      @client.org_members(org)
    end

    PULL_REQUEST_GRAPHQL = <<~GRAPHQL
      query($ids: [ID!]!) {
        nodes(ids: $ids) {
          ... on PullRequest {
            number
            title
            body
            merged_at: mergedAt
            merge_commit: mergeCommit { oid }
            url
            author { login url }
            assignees(first: 10) { nodes { login } }
            labels(first: 20) { nodes { name } }
            repository { url is_private: isPrivate }
          }
        }
      }
    GRAPHQL

    def pull_requests_by_node_ids(node_ids)
      response = @client.post(
        graphql_path,
        { query: PULL_REQUEST_GRAPHQL, variables: { ids: node_ids } }.to_json
      )
      response.data.nodes
    end

    private

    def graphql_path
      '/graphql'
    end

    def warn_if_insecure_netrc
      netrc_path = File.expand_path('~/.netrc')
      return if (File.stat(netrc_path).mode & 0o777) == 0o600

      warn 'WARNING: ~/.netrc has insecure permissions. Run: chmod 600 ~/.netrc'
    end
  end
end
