# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'whatsup_github/config_reader'
require 'whatsup_github/custom_formatter'

RSpec.describe WhatsupGithub::CustomFormatter do
  def build_row(overrides = {})
    double('row', to_h: { 'description' => 'Added a thing' }.merge(overrides))
  end

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  def stub_template_path(path)
    config = instance_double(WhatsupGithub::Config, template_path: path)
    allow(WhatsupGithub::Config).to receive(:instance).and_return(config)
  end

  it 'renders rows through the configured project-relative template' do
    File.write('custom.mustache', "{{#rows}}{{{description}}}\n{{/rows}}")
    stub_template_path('custom.mustache')

    expect(described_class.new.generate_output_from([build_row])).to eq("Added a thing\n")
  end

  it 'renders rows through a template in a nested subdirectory' do
    FileUtils.mkdir_p('templates')
    File.write('templates/custom.mustache', "{{#rows}}{{{description}}}\n{{/rows}}")
    stub_template_path('templates/custom.mustache')

    expect(described_class.new.generate_output_from([build_row])).to eq("Added a thing\n")
  end

  it 'renders an internal symlink using the validated canonical path' do
    File.write('custom.mustache', '{{#rows}}{{{description}}}{{/rows}}')
    File.symlink('custom.mustache', 'linked.mustache')
    stub_template_path('linked.mustache')
    expect(File).to receive(:read).with(File.realpath('custom.mustache')).and_call_original

    expect(described_class.new.generate_output_from([build_row])).to eq('Added a thing')
  end

  it 'renders a template when the working root is a symlink' do
    File.write('custom.mustache', '{{#rows}}{{{description}}}{{/rows}}')
    File.symlink(Dir.pwd, 'project-link')
    linked_root = File.expand_path('project-link')
    allow(Dir).to receive(:pwd).and_return(linked_root)
    stub_template_path('custom.mustache')

    expect(described_class.new.generate_output_from([build_row])).to eq('Added a thing')
  end

  it 'aborts on a sibling directory sharing the project path prefix' do
    Dir.mktmpdir("#{File.basename(Dir.pwd)}-sibling", File.dirname(Dir.pwd)) do |sibling|
      template = File.join(sibling, 'custom.mustache')
      File.write(template, 'Outside template')
      stub_template_path(template)

      expect { described_class.new.generate_output_from([]) }
        .to raise_error(SystemExit)
        .and output(/must point to a file inside the project directory/).to_stderr
    end
  end

  it 'aborts on an in-project symlink to an outside template' do
    Dir.mktmpdir do |outside|
      template = File.join(outside, 'custom.mustache')
      File.write(template, 'Outside template')
      File.symlink(template, 'linked.mustache')
      stub_template_path('linked.mustache')

      expect { described_class.new.generate_output_from([]) }
        .to raise_error(SystemExit)
        .and output(/must point to a file inside the project directory/).to_stderr
    end
  end

  it 'aborts when templates.custom is not configured' do
    stub_template_path(nil)

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/'templates.custom' is not set/).to_stderr
  end

  it 'aborts on path traversal outside the project directory' do
    stub_template_path('../../../../etc/passwd')

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/must point to a file inside the project directory/).to_stderr
  end

  it 'aborts on an absolute path outside the project directory' do
    stub_template_path('/etc/passwd')

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/must point to a file inside the project directory/).to_stderr
  end

  it 'aborts when the configured template file does not exist' do
    stub_template_path('missing.mustache')

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/Template file not found/).to_stderr
  end

  it 'aborts when the configured template is a dangling symlink' do
    File.symlink('missing.mustache', 'linked.mustache')
    stub_template_path('linked.mustache')

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/Template file not found/).to_stderr
  end

  it 'aborts when the working root cannot be canonicalized' do
    allow(Dir).to receive(:pwd).and_return(File.expand_path('missing-project'))
    stub_template_path('custom.mustache')

    expect { described_class.new.generate_output_from([]) }
      .to raise_error(SystemExit)
      .and output(/Template file not found/).to_stderr
  end
end
