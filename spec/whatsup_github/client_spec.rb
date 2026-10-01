# frozen_string_literal: true

require 'octokit'
require 'tmpdir'
require 'whatsup_github/client'

RSpec.describe WhatsupGithub::Client do
  describe '#initialize' do
    it 'authenticates with an access token when present' do
      stub_const('WhatsupGithub::Client::WHATSUP_GITHUB_ACCESS_TOKEN', 'tok123')
      expect(Octokit::Client).to receive(:new).with(access_token: 'tok123')

      described_class.instance
    end

    it 'authenticates via netrc when no token is present and netrc exists' do
      stub_const('WhatsupGithub::Client::WHATSUP_GITHUB_ACCESS_TOKEN', nil)
      stub_netrc_permissions(0o100_600)
      expect(Octokit::Client).to receive(:new).with(netrc: true)

      described_class.instance
    end

    it 'warns about insecure netrc permissions' do
      stub_const('WhatsupGithub::Client::WHATSUP_GITHUB_ACCESS_TOKEN', nil)
      stub_netrc_permissions(0o100_644)
      allow(Octokit::Client).to receive(:new)

      expect { described_class.instance }.to output(/insecure permissions/).to_stderr
    end

    it 'falls back to an unauthenticated guest client with a warning' do
      stub_const('WhatsupGithub::Client::WHATSUP_GITHUB_ACCESS_TOKEN', nil)
      stub_netrc(exists: false)
      expect(Octokit::Client).to receive(:new).with(no_args)

      expect { described_class.instance }.to output(/rate limit: 60/).to_stderr
    end
  end

  describe 'delegation' do
    let(:octokit) { instance_double(Octokit::Client) }

    before do
      stub_const('WhatsupGithub::Client::WHATSUP_GITHUB_ACCESS_TOKEN', 'tok123')
      allow(Octokit::Client).to receive(:new).and_return(octokit)
    end

    it '#search_issues delegates to the underlying client' do
      allow(octokit).to receive(:search_issues).with('query').and_return('result')

      expect(described_class.instance.search_issues('query')).to eq('result')
    end

    it '#pull_request delegates to the underlying client' do
      allow(octokit).to receive(:pull_request).with('org/repo', 42).and_return('pr')

      expect(described_class.instance.pull_request('org/repo', 42)).to eq('pr')
    end

    it '#org_members delegates to the underlying client' do
      allow(octokit).to receive(:org_members).with('org').and_return(['member'])

      expect(described_class.instance.org_members('org')).to eq(['member'])
    end

    it '#pull_requests_by_node_ids posts the GraphQL query and returns the nodes' do
      response = double('response', data: double('data', nodes: %w[a b]))
      expect(octokit).to receive(:post).with('/graphql', anything).and_return(response)

      expect(described_class.instance.pull_requests_by_node_ids(['id1'])).to eq(%w[a b])
    end
  end
end
