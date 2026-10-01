# frozen_string_literal: true

require 'whatsup_github/cli'

RSpec.describe WhatsupGithub::CLI do
  describe '#since' do
    let(:runner) { instance_double(WhatsupGithub::Runner, run: nil) }

    before do
      allow(WhatsupGithub::Runner).to receive(:new).and_return(runner)
      allow(WhatsupGithub::Config).to receive(:filename=)
    end

    it 'sets Config.filename from the --config option and runs the runner' do
      described_class.start(['since', 'jun 10', '--config', 'custom.yml'])

      expect(WhatsupGithub::Config).to have_received(:filename=).with('custom.yml')
      expect(WhatsupGithub::Runner).to have_received(:new).with(Date.parse('jun 10'))
      expect(runner).to have_received(:run)
    end

    it 'defaults --config to .whatsup.yml' do
      described_class.start(['since', 'jun 10'])

      expect(WhatsupGithub::Config).to have_received(:filename=).with('.whatsup.yml')
    end

    it 'defaults to 7 days ago when no date is given' do
      allow(Date).to receive(:today).and_return(Date.new(2026, 9, 29))

      described_class.start(['since'])

      expect(WhatsupGithub::Runner).to have_received(:new).with(Date.new(2026, 9, 22))
    end
  end

  describe '#version' do
    it 'prints the current gem version' do
      expect { described_class.start(['version']) }.to output(/Current version is #{WhatsupGithub::VERSION}/).to_stdout
    end
  end
end
