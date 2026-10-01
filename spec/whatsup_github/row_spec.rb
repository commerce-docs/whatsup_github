# frozen_string_literal: true

require 'time'
require 'whatsup_github/config_reader'
require 'whatsup_github/row'

RSpec.describe WhatsupGithub::Row do
  let(:config) do
    instance_double(WhatsupGithub::Config, labels: %w[technical release-notes 2.4], magic_word: 'whatsnew')
  end

  before { allow(WhatsupGithub::Config).to receive(:instance).and_return(config) }

  def build_row(overrides = {})
    described_class.new({
      pr_number: 42,
      pr_title: 'Add a feature',
      pr_body: "Some intro\nwhatsnew\n* Added a thing\r\n* Fixed another\n",
      date: Time.parse('2026-09-01T12:00:00Z'),
      pr_labels: %w[technical 2.4],
      assignee: 'octocat',
      author: 'octocat',
      author_url: 'https://github.com/octocat',
      pr_url: 'https://github.com/org/repo/pull/42',
      merge_commit_sha: 'abc123'
    }.merge(overrides))
  end

  describe '#date' do
    it 'returns the ISO date' do
      expect(build_row.date).to eq('2026-09-01')
    end
  end

  describe '#date_string' do
    it 'returns a human-readable date' do
      expect(build_row.date_string).to eq('September 1, 2026')
    end
  end

  describe '#type' do
    it 'intersects row labels with configured labels' do
      expect(build_row.type).to eq('technical, 2.4')
    end

    it 'is empty when no labels match' do
      expect(build_row(pr_labels: %w[unrelated]).type).to eq('')
    end
  end

  describe '#required_labels' do
    it 'returns the configured required labels' do
      allow(config).to receive(:required_labels).and_return(['best-practices'])

      expect(build_row.required_labels).to eq(['best-practices'])
    end
  end

  describe '#versions' do
    it 'selects labels that look like version numbers' do
      expect(build_row(pr_labels: %w[technical 2.4 3.1]).versions).to eq('2.4, 3.1')
    end

    it 'selects version labels with multiple-digit prefixes' do
      expect(build_row(pr_labels: %w[2.4 12.3 123.4]).versions).to eq('2.4, 12.3, 123.4')
    end

    it 'is empty when no version-like labels are present' do
      expect(build_row(pr_labels: ['technical', 'v2.4', 'release-12.3', '12', '12x3', "notes\n2.4"]).versions).to eq('')
    end
  end

  describe '#magic_word' do
    it 'returns the configured magic word' do
      expect(build_row.magic_word).to eq('whatsnew')
    end

    it 'aborts when the magic word is not configured' do
      allow(config).to receive(:magic_word).and_return(nil)
      expect { build_row.magic_word }.to raise_error(SystemExit)
    end
  end

  describe '#description' do
    it 'parses the body after the magic word into <br/>-joined lines' do
      expect(build_row.description).to eq('Added a thing<br/>Fixed another')
    end

    it 'warns and returns a message when the magic word is missing from the body' do
      row = build_row(pr_body: 'No magic word here')
      message = nil
      expect { message = row.description }.to output(/MISSING whatsnew/).to_stdout
      expect(message).to include('#42').and include('octocat').and include('pull/42')
    end
  end

  describe '#to_h' do
    it 'returns the full raw field set' do
      expect(build_row.to_h).to eq(
        'description' => 'Added a thing<br/>Fixed another',
        'versions' => '2.4',
        'type' => 'technical, 2.4',
        'date' => '2026-09-01',
        'link' => 'https://github.com/org/repo/pull/42',
        'merge_commit' => 'abc123',
        'contributor' => 'octocat',
        'labels' => %w[technical 2.4]
      )
    end
  end
end
