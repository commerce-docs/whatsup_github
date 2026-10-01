# frozen_string_literal: true

require 'whatsup_github/table'

RSpec.describe WhatsupGithub::Table do
  def build_row(description:, versions:, type:, date:)
    double('row', description:, versions:, type:, date:)
  end

  it 'renders four-column Markdown rows without a header' do
    rows = [build_row(description: 'Sample entry', versions: '2.4', type: 'technical', date: '2026-09-01')]

    expect(described_class.new.generate_output_from(rows)).to eq(<<~MARKDOWN)
      | Sample entry | 2.4 | technical | 2026-09-01 |
    MARKDOWN
  end

  it 'matches the 2.0.0 serializer for multiple rows and empty fields' do
    rows = [
      build_row(description: '[Sample](https://example.com) & <br/>  details', versions: '2.4, 2.5', type: 'technical', date: '2026-09-01'),
      build_row(description: 'Another entry', versions: '', type: '', date: '2026-09-02')
    ]
    legacy_output = rows.collect do |row|
      "| #{row.description} | #{row.versions} | #{row.type} | #{row.date} |\n".tr_s(' ', ' ')
    end.join

    expect(described_class.new.generate_output_from(rows)).to eq(legacy_output)
  end

  it 'renders an empty string when there are no rows' do
    expect(described_class.new.generate_output_from([])).to eq('')
  end
end
