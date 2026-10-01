# frozen_string_literal: true

require 'time'
require 'whatsup_github/row_collector'

RSpec.describe WhatsupGithub::RowCollector do
  let(:since) { Date.new(2026, 9, 1) }
  let(:config) { instance_double(WhatsupGithub::Config, repos: ['octokit/octokit.rb']) }

  before { allow(WhatsupGithub::Config).to receive(:instance).and_return(config) }

  def build_pull(overrides = {})
    defaults = {
      number: 42,
      title: 'Add a feature',
      body: 'whatsnew stuff',
      merged_at: Time.parse('2026-09-01T12:00:00Z'),
      labels: double('labels', nodes: [double('label', name: 'technical')]),
      assignees: double('assignees', nodes: []),
      merge_commit: double('merge_commit', oid: 'abc123'),
      author: double('author', login: 'octocat', url: 'https://github.com/octocat'),
      url: 'https://github.com/org/repo/pull/42'
    }
    double('pull', defaults.merge(overrides))
  end

  def stub_pulls(repo: 'octokit/octokit.rb', data:)
    pulls = instance_double(WhatsupGithub::Pulls, data: data)
    allow(WhatsupGithub::Pulls).to receive(:new).with(repo: repo, since: since).and_return(pulls)
  end

  describe '#collect_rows' do
    it 'maps GraphQL pull data into Row objects' do
      stub_pulls(data: [build_pull])

      row = described_class.new(since: since).collect_rows.first

      expect(row.pr_number).to eq(42)
      expect(row.title).to eq('Add a feature')
      expect(row.labels).to eq(['technical'])
      expect(row.assignee).to eq('NOBODY')
      expect(row.merge_commit).to eq('abc123')
      expect(row.author).to eq('octocat')
      expect(row.author_url).to eq('https://github.com/octocat')
      expect(row.link).to eq('https://github.com/org/repo/pull/42')
    end

    it 'joins multiple assignee logins' do
      pull = build_pull(assignees: double('assignees', nodes: [
                          double('a', login: 'alice'), double('a', login: 'bob')
                        ]))
      stub_pulls(data: [pull])

      expect(described_class.new(since: since).collect_rows.first.assignee).to eq('alice, bob')
    end

    it 'rewrites the link for enterprise-prefixed repos' do
      allow(config).to receive(:repos).and_return(['enterprise:org/repo'])
      stub_pulls(repo: 'enterprise:org/repo', data: [build_pull])

      expect(described_class.new(since: since).collect_rows.first.link).to eq('enterprise:org/repo/pull/42')
    end

    it 'handles a nil merge_commit and author gracefully' do
      stub_pulls(data: [build_pull(merge_commit: nil, author: nil)])

      row = described_class.new(since: since).collect_rows.first

      expect(row.merge_commit).to be_nil
      expect(row.author).to be_nil
      expect(row.author_url).to be_nil
    end
  end

  describe '#sort_by_date' do
    it 'sorts rows by date, most recent first' do
      older = build_pull(number: 1, merged_at: Time.parse('2026-08-01T00:00:00Z'))
      newer = build_pull(number: 2, merged_at: Time.parse('2026-09-01T00:00:00Z'))
      stub_pulls(data: [older, newer])

      sorted = described_class.new(since: since).sort_by_date

      expect(sorted.map(&:pr_number)).to eq([2, 1])
    end
  end
end
