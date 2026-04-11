# frozen_string_literal: true

require 'singleton'

# Client authorization
module WhatsupGithub
  # Create a singleton object for EnterpriseClient.
  # Authorize with a GitHub Enterprise token from $WHATSUP_ENTERPRISE_ACCESS_TOKEN if available
  # Otherwise, use credentials from ~/.netrc
  class EnterpriseClient < Client
    include Singleton

    WHATSUP_ENTERPRISE_ACCESS_TOKEN = ENV['WHATSUP_ENTERPRISE_ACCESS_TOKEN']
    WHATSUP_GITHUB_ENTERPRISE_HOSTNAME = ENV['WHATSUP_GITHUB_ENTERPRISE_HOSTNAME']
    private_constant :WHATSUP_ENTERPRISE_ACCESS_TOKEN, :WHATSUP_GITHUB_ENTERPRISE_HOSTNAME

    @@hostname = ''

    VALID_HOSTNAME = /\A[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\z/
    PRIVATE_HOSTNAME = /\A(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|169\.254\.)/

    def self.host=(hostname)
      hostname = 'github.com' if hostname.nil? || hostname.empty?
      abort "ERROR: Invalid hostname: '#{hostname}'" unless hostname.match?(VALID_HOSTNAME)
      abort "ERROR: Private/internal addresses are not allowed for 'enterprise'" if hostname.match?(PRIVATE_HOSTNAME)
      @@hostname = hostname
    end

    def initialize
      self.class.host = WHATSUP_GITHUB_ENTERPRISE_HOSTNAME
      unless @@hostname == 'github.com'
        Octokit.configure do |c|
          c.api_endpoint = "https://#{@@hostname}/api/v3/"
        end
      end
      @client =
        if WHATSUP_ENTERPRISE_ACCESS_TOKEN
          Octokit::Client.new(access_token: WHATSUP_ENTERPRISE_ACCESS_TOKEN)
        elsif File.exist?(File.expand_path('~/.netrc'))
          warn_if_insecure_netrc
          Octokit::Client.new(netrc: true)
        else
          abort 'ERROR: No credentials found for GitHub Enterprise. ' \
                'Set WHATSUP_ENTERPRISE_ACCESS_TOKEN or configure ~/.netrc.'
        end
    end

    def search_issues(query)
      @client.search_issues(query.gsub('enterprise:', ''))
    end

    private

    def graphql_path
      @@hostname == 'github.com' ? '/graphql' : "https://#{@@hostname}/api/graphql"
    end
  end
end
