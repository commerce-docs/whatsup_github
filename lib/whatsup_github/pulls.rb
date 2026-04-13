# frozen_string_literal: true

require 'octokit'
require_relative 'config_reader'
require_relative 'client'
require_relative 'enterprise_client'

module WhatsupGithub
  # Gets issues found on GitHub by query
  class Pulls
    attr_reader :since, :repo

    def initialize(args = {})
      @repo = args[:repo]
      @since = args[:since]
    end

    def data
      node_ids = filtered_node_ids
      return [] if node_ids.empty?

      if @repo.start_with? 'enterprise:'
        enterprise_client.pull_requests_by_node_ids(node_ids)
      else
        client.pull_requests_by_node_ids(node_ids)
      end
    rescue Octokit::Unauthorized
      abort 'ERROR: Authentication failed. Check your access token.'
    rescue Octokit::Forbidden
      abort 'ERROR: Access forbidden. Verify token scopes or check your API rate limit.'
    rescue Octokit::Error => e
      abort "ERROR: GitHub API error: #{e.message}"
    rescue Faraday::Error => e
      abort "ERROR: Network error: #{e.message}"
    end

    private

    def configuration
      Config.instance
    end

    def optional_labels
      configuration.optional_labels
    end

    def required_labels
      configuration.required_labels
    end

    def magic_word
      configuration.magic_word
    end

    def base_branch
      configuration.base_branch
    end

    def client
      Client.instance
    end

    def enterprise_client
      EnterpriseClient.instance
    end

    def search_issues(label)
      auto_paginate
      call_query query(label)
    end

    def search_issues_with_magic_word(label)
      auto_paginate
      call_query query_with_magic_word(label)
    end

    def call_query(query)
      warn "DEBUG: #{query}" if ENV['DEBUG']
      if repo.start_with? 'enterprise:'
        enterprise_client.search_issues(query)
      else
        client.search_issues(query)
      end
    rescue Octokit::Unauthorized
      abort 'ERROR: Authentication failed. Check your access token.'
    rescue Octokit::Forbidden
      abort 'ERROR: Access forbidden. Verify token scopes or check your API rate limit.'
    rescue Octokit::NotFound
      abort "ERROR: Repository not found: #{repo.delete_prefix('enterprise:')}"
    rescue Octokit::Error => e
      abort "ERROR: GitHub API error: #{e.message}"
    rescue Faraday::Error => e
      abort "ERROR: Network error: #{e.message}"
    end

    def query(label)
      "repo:#{repo} label:\"#{label}\" merged:>=#{since} base:#{base_branch} is:pull-request"
    end

    def query_with_magic_word(label)
      query(label) + " \"#{magic_word}\" in:body"
    end

    def auto_paginate
      Octokit.auto_paginate = true
    end

    def filtered_issues
      issues = []
      required_labels.each do |label|
        issues += search_issues(label).items
      end
      optional_labels.each do |label|
        issues += search_issues_with_magic_word(label).items
      end
      issues
    end

    def filtered_node_ids
      filtered_issues.map(&:node_id)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'date'
  two_weeks_ago = (Date.today - 14).to_s
  pulls = WhatsupGithub::Pulls.new(repo: 'magento/devdocs', since: two_weeks_ago)
  p pulls.data
end
