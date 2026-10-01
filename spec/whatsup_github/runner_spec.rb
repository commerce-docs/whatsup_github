# frozen_string_literal: true

require 'tmpdir'
require 'whatsup_github/runner'

RSpec.describe WhatsupGithub::Runner do
  let(:date) { Date.new(2026, 9, 1) }
  let(:config) { instance_double(WhatsupGithub::Config, output_format: ['markdown'], custom_output: nil) }
  let(:generator) { instance_double(WhatsupGithub::Generator, content: ['row1'], run: 'rendered') }

  before do
    allow(WhatsupGithub::Config).to receive(:instance).and_return(config)
    allow(WhatsupGithub::Generator).to receive(:new).with(date).and_return(generator)
  end

  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  describe '#run' do
    it 'raises when output_format is missing' do
      allow(config).to receive(:output_format).and_return(nil)

      expect { described_class.new(date).run }.to raise_error(/Cannot find "output_format"/)
    end

    it 'writes markdown output when configured' do
      described_class.new(date).run

      expect(File.exist?('tmp/whats-new-on-devdocs.md')).to be true
    end

    it 'writes yaml output when configured' do
      allow(config).to receive(:output_format).and_return(['yaml'])

      described_class.new(date).run

      expect(File.exist?('tmp/whats-new.yml')).to be true
    end

    it 'writes custom output when configured and custom_output is set' do
      allow(config).to receive_messages(output_format: ['custom'], custom_output: 'tmp/custom.md')

      described_class.new(date).run

      expect(File.exist?('tmp/custom.md')).to be true
    end

    it 'aborts when output_format includes custom but custom_output is not set' do
      allow(config).to receive(:output_format).and_return(['custom'])

      expect { described_class.new(date).run }.to raise_error(SystemExit)
    end
  end

  describe '#write_results' do
    it 'creates missing directories, writes the file, and prints a completion message' do
      formatter = double('formatter', generate_output_from: 'content')
      runner = described_class.new(date)

      expect { runner.write_results('nested/dir/out.md', formatter) }.to output(/Done!/).to_stdout
      expect(File.read('nested/dir/out.md')).to eq('rendered')
    end
  end
end
