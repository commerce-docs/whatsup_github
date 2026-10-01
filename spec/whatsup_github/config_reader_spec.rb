# frozen_string_literal: true

require 'tmpdir'
require 'whatsup_github/config_reader'

RSpec.describe WhatsupGithub::Config do
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  describe '.filename=' do
    it 'accepts a relative path' do
      expect { described_class.filename = 'custom.yml' }.not_to raise_error
    end

    it 'rejects paths containing ..' do
      expect { described_class.filename = '../evil.yml' }.to raise_error(SystemExit)
    end

    it 'rejects absolute paths' do
      expect { described_class.filename = '/etc/passwd' }.to raise_error(SystemExit)
    end
  end

  describe '#read' do
    it 'parses an existing config file' do
      File.write('.whatsup.yml', "---\nbase_branch: main\n")
      described_class.filename = '.whatsup.yml'

      expect(described_class.instance.read['base_branch']).to eq('main')
    end

    it 'copies the scaffold config when the file is missing' do
      described_class.filename = '.whatsup.yml'
      described_class.instance.read

      expect(File.exist?('.whatsup.yml')).to be true
    end
  end

  describe 'accessors' do
    before do
      File.write('.whatsup.yml', <<~YAML)
        ---
        base_branch: main
        repos:
          - octokit/octokit.rb
        labels:
          required:
            - enhancement
          optional:
            - technical
        output_format:
          - yaml
        magic_word: whatsnew
        membership: AdobeDocs
        templates:
          custom: custom.mustache
        custom_output: tmp/out.md
      YAML
      described_class.filename = '.whatsup.yml'
    end

    it 'exposes repos' do
      expect(described_class.instance.repos).to eq(['octokit/octokit.rb'])
    end

    it 'exposes base_branch' do
      expect(described_class.instance.base_branch).to eq('main')
    end

    it 'exposes output_format' do
      expect(described_class.instance.output_format).to eq(['yaml'])
    end

    it 'merges required and optional labels' do
      expect(described_class.instance.labels).to eq(%w[enhancement technical])
    end

    it 'exposes required_labels and optional_labels separately' do
      expect(described_class.instance.required_labels).to eq(['enhancement'])
      expect(described_class.instance.optional_labels).to eq(['technical'])
    end

    it 'exposes membership' do
      expect(described_class.instance.membership).to eq('AdobeDocs')
    end

    it 'exposes magic_word' do
      expect(described_class.instance.magic_word).to eq('whatsnew')
    end

    it 'exposes the custom template_path' do
      expect(described_class.instance.template_path).to eq('custom.mustache')
    end

    it 'exposes custom_output' do
      expect(described_class.instance.custom_output).to eq('tmp/out.md')
    end
  end

  describe 'missing optional sections' do
    before do
      File.write('.whatsup.yml', "---\nbase_branch: main\n")
      described_class.filename = '.whatsup.yml'
    end

    it 'defaults required_labels and optional_labels to an empty array' do
      expect(described_class.instance.required_labels).to eq([])
      expect(described_class.instance.optional_labels).to eq([])
    end

    it 'defaults template_path and custom_output to nil' do
      expect(described_class.instance.template_path).to be_nil
      expect(described_class.instance.custom_output).to be_nil
    end
  end
end
