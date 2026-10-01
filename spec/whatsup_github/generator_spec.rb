# frozen_string_literal: true

require 'whatsup_github/generator'
require 'whatsup_github/row_collector'

RSpec.describe WhatsupGithub::Generator do
  let(:since) { Date.new(2026, 9, 1) }
  let(:collector) { instance_double(WhatsupGithub::RowCollector, sort_by_date: %w[row1 row2]) }

  before { allow(WhatsupGithub::RowCollector).to receive(:new).with(since:).and_return(collector) }

  describe '#content' do
    it 'delegates to RowCollector#sort_by_date' do
      expect(described_class.new(since).content).to eq(%w[row1 row2])
    end
  end

  describe '#run' do
    it 'delegates to the formatter' do
      formatter = double('formatter', generate_output_from: 'rendered')
      expect(described_class.new(since).run(formatter, %w[row1 row2])).to eq('rendered')
      expect(formatter).to have_received(:generate_output_from).with(%w[row1 row2])
    end
  end
end
