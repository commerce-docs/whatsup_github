# frozen_string_literal: true

require 'yaml'
require 'whatsup_github/yaml_formatter'

RSpec.describe WhatsupGithub::YAMLFormatter do
  def build_row(overrides = {})
    double('row', to_h: {
      'description' => 'Added a thing',
      'versions' => '2.4',
      'type' => 'technical',
      'date' => '2026-09-01',
      'link' => 'https://github.com/org/repo/pull/42',
      'merge_commit' => 'abc123',
      'contributor' => 'octocat',
      'labels' => %w[technical 2.4]
    }.merge(overrides))
  end

  it 'renders YAML that round-trips through YAML.safe_load' do
    output = described_class.new.generate_output_from([build_row])
    parsed = YAML.safe_load(output)

    expect(parsed['entries']).to eq(
      [
        {
          'description' => 'Added a thing',
          'versions' => '2.4',
          'type' => 'technical',
          'date' => '2026-09-01',
          'link' => 'https://github.com/org/repo/pull/42',
          'merge_commit' => 'abc123',
          'contributor' => 'octocat',
          'labels' => %w[technical 2.4]
        }
      ]
    )
  end

  it 'serializes the output object directly to YAML' do
    now = Time.now
    allow(Time).to receive(:now).and_return(now)
    row = build_row
    output = described_class.new.generate_output_from([row])

    expect(output).to eq(
      {
        'updated' => now.strftime('%c').tr_s(' ', ' '),
        'entries' => [row.to_h]
      }.to_yaml
    )
  end

  it 'renders an empty entries list without error' do
    output = described_class.new.generate_output_from([])
    expect(YAML.safe_load(output)['entries']).to eq([])
  end
end
