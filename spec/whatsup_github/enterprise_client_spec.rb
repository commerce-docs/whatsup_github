# frozen_string_literal: true

require 'octokit'
require 'whatsup_github/enterprise_client'

RSpec.describe WhatsupGithub::EnterpriseClient do
  before do
    stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', nil)
    stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_GITHUB_ENTERPRISE_HOSTNAME', nil)
  end

  describe '.host=' do
    it 'defaults to github.com when blank' do
      expect { described_class.host = '' }.not_to raise_error
    end

    it 'accepts a valid custom hostname' do
      expect { described_class.host = 'git.example.com' }.not_to raise_error
    end

    it 'rejects an invalid hostname format' do
      expect { described_class.host = 'not a host!' }.to raise_error(SystemExit)
    end

    it 'rejects private/internal hostnames' do
      %w[localhost 127.0.0.1 10.0.0.5 192.168.1.1 172.16.0.1 172.31.255.255 169.254.1.1].each do |host|
        expect { described_class.host = host }.to raise_error(SystemExit)
      end
    end

    it 'allows addresses just outside the private ranges' do
      expect { described_class.host = '172.15.0.1' }.not_to raise_error
      expect { described_class.host = '172.32.0.1' }.not_to raise_error
    end
  end

  describe '#initialize' do
    it 'authenticates with the enterprise access token when present' do
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', 'tok123')
      expect(Octokit::Client).to receive(:new).with(access_token: 'tok123')

      described_class.instance
    end

    it 'authenticates via netrc when no token is present and netrc exists' do
      stub_netrc_permissions(0o100_600)
      expect(Octokit::Client).to receive(:new).with(netrc: true)

      described_class.instance
    end

    it 'aborts when no credentials are configured' do
      stub_netrc(exists: false)

      expect { described_class.instance }.to raise_error(SystemExit)
    end

    it 'configures a custom API endpoint for a non-default hostname' do
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_GITHUB_ENTERPRISE_HOSTNAME', 'git.example.com')
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', 'tok123')
      allow(Octokit::Client).to receive(:new)
      expect(Octokit).to receive(:configure).and_yield(Octokit)
      expect(Octokit).to receive(:api_endpoint=).with('https://git.example.com/api/v3/')

      described_class.instance
    end
  end

  describe '#search_issues' do
    it 'strips the enterprise: prefix before querying' do
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', 'tok123')
      octokit = instance_double(Octokit::Client)
      allow(Octokit::Client).to receive(:new).and_return(octokit)
      allow(octokit).to receive(:search_issues).with('repo:org/repo label:"x"').and_return('result')

      result = described_class.instance.search_issues('repo:enterprise:org/repo label:"x"')

      expect(result).to eq('result')
    end
  end

  describe '#pull_requests_by_node_ids' do
    it 'posts to /graphql for the default github.com hostname' do
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', 'tok123')
      octokit = instance_double(Octokit::Client)
      allow(Octokit::Client).to receive(:new).and_return(octokit)
      response = double('response', data: double('data', nodes: %w[a]))
      expect(octokit).to receive(:post).with('/graphql', anything).and_return(response)

      expect(described_class.instance.pull_requests_by_node_ids(['id1'])).to eq(%w[a])
    end

    it 'posts to the enterprise GraphQL endpoint for a custom hostname' do
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_GITHUB_ENTERPRISE_HOSTNAME', 'git.example.com')
      stub_const('WhatsupGithub::EnterpriseClient::WHATSUP_ENTERPRISE_ACCESS_TOKEN', 'tok123')
      allow(Octokit).to receive(:configure)
      octokit = instance_double(Octokit::Client)
      allow(Octokit::Client).to receive(:new).and_return(octokit)
      response = double('response', data: double('data', nodes: %w[a]))
      expect(octokit).to receive(:post).with('https://git.example.com/api/graphql', anything).and_return(response)

      expect(described_class.instance.pull_requests_by_node_ids(['id1'])).to eq(%w[a])
    end
  end
end
