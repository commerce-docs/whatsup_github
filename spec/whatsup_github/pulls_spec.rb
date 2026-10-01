# frozen_string_literal: true

require 'octokit'
require 'faraday'
require 'whatsup_github/pulls'

RSpec.describe WhatsupGithub::Pulls do
  let(:since) { Date.new(2026, 9, 1) }
  let(:config) do
    instance_double(WhatsupGithub::Config, required_labels: ['enhancement'], optional_labels: [],
                                            magic_word: 'whatsnew', base_branch: 'main')
  end

  before { allow(WhatsupGithub::Config).to receive(:instance).and_return(config) }

  def build_pulls(repo: 'octokit/octokit.rb')
    described_class.new(repo: repo, since: since)
  end

  def stub_search(client, node_ids: ['node1'], expected_query: nil)
    issues = node_ids.map { |id| double('issue', node_id: id) }
    result = double('result', items: issues)
    if expected_query
      allow(client).to receive(:search_issues).with(expected_query).and_return(result)
    else
      allow(client).to receive(:search_issues).and_return(result)
    end
  end

  shared_examples 'a Pulls client failure' do |raising_method, error, message|
    it "aborts with #{message.inspect}" do
      client = instance_double(WhatsupGithub::Client)
      allow(WhatsupGithub::Client).to receive(:instance).and_return(client)
      stub_search(client) if raising_method == :pull_requests_by_node_ids
      allow(client).to receive(raising_method).and_raise(error)

      expect { build_pulls.data }.to raise_error(SystemExit).and output(message).to_stderr
    end
  end

  describe '#data' do
    it 'returns [] without contacting the client when there are no configured labels' do
      allow(config).to receive_messages(required_labels: [], optional_labels: [])
      client = instance_double(WhatsupGithub::Client)
      allow(client).to receive(:search_issues)
      allow(WhatsupGithub::Client).to receive(:instance).and_return(client)

      expect(build_pulls.data).to eq([])
      expect(client).not_to have_received(:search_issues)
    end

    it 'fetches PRs for a standard repo, building the expected search query' do
      client = instance_double(WhatsupGithub::Client)
      allow(WhatsupGithub::Client).to receive(:instance).and_return(client)
      expected_query = 'repo:octokit/octokit.rb label:"enhancement" merged:>=2026-09-01 base:main is:pull-request'
      stub_search(client, expected_query: expected_query)
      allow(client).to receive(:pull_requests_by_node_ids).with(['node1']).and_return(['pr'])

      expect(build_pulls.data).to eq(['pr'])
    end

    it 'searches optional labels with the magic word appended to the query' do
      allow(config).to receive_messages(required_labels: [], optional_labels: ['technical'])
      client = instance_double(WhatsupGithub::Client)
      allow(WhatsupGithub::Client).to receive(:instance).and_return(client)
      expected_query = 'repo:octokit/octokit.rb label:"technical" merged:>=2026-09-01 base:main ' \
                        'is:pull-request "whatsnew" in:body'
      stub_search(client, expected_query: expected_query)
      allow(client).to receive(:pull_requests_by_node_ids).with(['node1']).and_return(['pr'])

      expect(build_pulls.data).to eq(['pr'])
    end

    it 'routes enterprise-prefixed repos through the enterprise client' do
      enterprise_client = instance_double(WhatsupGithub::EnterpriseClient)
      allow(WhatsupGithub::EnterpriseClient).to receive(:instance).and_return(enterprise_client)
      stub_search(enterprise_client)
      allow(enterprise_client).to receive(:pull_requests_by_node_ids).with(['node1']).and_return(['pr'])

      expect(build_pulls(repo: 'enterprise:org/repo').data).to eq(['pr'])
    end

    context 'when the search request fails' do
      it_behaves_like 'a Pulls client failure', :search_issues, Octokit::Unauthorized, /Authentication failed/
      it_behaves_like 'a Pulls client failure', :search_issues, Octokit::Forbidden, /Access forbidden/
      it_behaves_like 'a Pulls client failure', :search_issues, Octokit::NotFound, /Repository not found/
      it_behaves_like 'a Pulls client failure', :search_issues, Octokit::Error, /GitHub API error/
      it_behaves_like 'a Pulls client failure', :search_issues, Faraday::Error.new('boom'), /Network error/
    end

    context 'when fetching PR nodes by id fails' do
      it_behaves_like 'a Pulls client failure', :pull_requests_by_node_ids, Octokit::Unauthorized, /Authentication failed/
      it_behaves_like 'a Pulls client failure', :pull_requests_by_node_ids, Octokit::Forbidden, /Access forbidden/
      it_behaves_like 'a Pulls client failure', :pull_requests_by_node_ids, Octokit::NotFound, /GitHub API error/
      it_behaves_like 'a Pulls client failure', :pull_requests_by_node_ids, Faraday::Error.new('boom'), /Network error/
    end
  end
end
