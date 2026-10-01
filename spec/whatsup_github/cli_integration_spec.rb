# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'yaml'
require 'vcr'
require 'whatsup_github/cli'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('../fixtures/cassettes', __dir__)
  config.hook_into :webmock
  config.default_cassette_options = { record: :none }
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<WHATSUP_GITHUB_ACCESS_TOKEN>') { ENV.fetch('WHATSUP_GITHUB_ACCESS_TOKEN', nil) }
end

RSpec.describe 'CLI integration' do
  let(:configuration) do
    {
      'base_branch' => 'main',
      'repos' => ['octokit/octokit.rb'],
      'labels' => { 'required' => ['enhancement'] },
      'output_format' => ['yaml'],
      'magic_word' => 'whatsnew'
    }
  end

  around do |example|
    Dir.mktmpdir { |directory| Dir.chdir(directory) { example.run } }
  end

  before do
    stub_netrc(exists: false)
    File.write('.whatsup.yml', configuration.to_yaml)
  end

  def run_executable(*arguments, environment: {})
    root = File.expand_path('../..', __dir__)
    Open3.capture3(
      { 'HOME' => Dir.pwd, 'WHATSUP_GITHUB_ACCESS_TOKEN' => nil }.merge(environment),
      RbConfig.ruby, '-I', File.join(root, 'lib'), File.join(root, 'exe/whatsup_github'), *arguments
    )
  end

  def run_since
    WhatsupGithub::CLI.start(['since', '2026-01-01'])
  end

  def read_output
    YAML.safe_load(File.read('tmp/whats-new.yml'))
  end

  describe 'the executable' do
    it 'prints the gem version and exits successfully' do
      stdout, stderr, result = run_executable('version')

      expect(result).to be_success
      expect(stdout).to include("Current version is #{WhatsupGithub::VERSION}")
      expect(stderr).to be_empty
    end

    it 'prints available commands with no arguments' do
      stdout, stderr, result = run_executable

      expect(result).to be_success
      expect(stdout).to include('Commands:', 'since', 'version')
      expect(stderr).to be_empty
    end

    it 'rejects a config path outside the project directory' do
      stdout, stderr, result = run_executable('since', '2026-01-01', '--config=../evil.yml')

      expect(result.exitstatus).to eq(1)
      expect(stderr).to include('ERROR: Invalid config path')
      expect(stdout).not_to include('Done!')
      expect(Dir.exist?('tmp')).to be false
    end

    it 'rejects a private enterprise hostname before any network call' do
      configuration['repos'] = ['enterprise:org/repo']
      File.write('.whatsup.yml', configuration.to_yaml)
      stdout, stderr, result = run_executable(
        'since', '2026-01-01', environment: { 'WHATSUP_GITHUB_ENTERPRISE_HOSTNAME' => 'localhost' }
      )

      expect(result).not_to be_success
      expect(stderr).to include('Private/internal addresses are not allowed')
      expect(stdout).not_to include('Done!')
      expect(Dir.exist?('tmp')).to be false
    end
  end

  describe 'output generation with no matching pull requests' do
    let(:custom_template_fixture) { File.expand_path('../fixtures/templates/custom.mustache', __dir__) }

    let(:search_request) do
      stub_request(:get, 'https://api.github.com/search/issues')
        .with(query: {
                'per_page' => '100',
                'q' => 'repo:octokit/octokit.rb label:"enhancement" merged:>=2026-01-01 base:main is:pull-request'
              })
        .to_return(body: { total_count: 0, incomplete_results: false, items: [] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    before { search_request }

    def configure_custom_output(template_path)
      configuration.merge!('output_format' => ['custom'],
                           'templates' => { 'custom' => template_path },
                           'custom_output' => 'tmp/whats-new-custom.md')
      File.write('.whatsup.yml', configuration.to_yaml)
    end

    it 'completes the basic since workflow' do
      expect { run_since }.to output(/Done!/).to_stdout
      expect(read_output['entries']).to eq([])
      expect(search_request).to have_been_requested.once
    end

    it 'writes empty markdown' do
      configuration['output_format'] = ['markdown']
      File.write('.whatsup.yml', configuration.to_yaml)

      expect { run_since }.to output(/Done!/).to_stdout
      expect(File.read('tmp/whats-new-on-devdocs.md')).to eq('')
    end

    it 'writes valid YAML with an empty entries array and an update timestamp' do
      expect { run_since }.to output(/Done!/).to_stdout
      expect(read_output).to include('entries' => [], 'updated' => a_kind_of(String))
    end

    it 'rejects a custom template outside the project directory' do
      configure_custom_output('../../../../etc/passwd')

      expect { run_since }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        .and output(/must point to a file inside the project directory/).to_stderr
      expect(Dir.exist?('tmp')).to be false
    end

    it 'renders a fixture template from a nested project path' do
      FileUtils.mkdir_p('templates/releases')
      FileUtils.cp(custom_template_fixture, 'templates/releases/custom.mustache')
      configure_custom_output('templates/releases/custom.mustache')

      expect { run_since }.to output(/Done!/).to_stdout
      expect(File.read('tmp/whats-new-custom.md')).to eq("Updates:\n")
    end

    it 'rejects a fixture template reached through a directory symlink escaping the project' do
      Dir.mktmpdir do |outside|
        FileUtils.cp(custom_template_fixture, File.join(outside, 'custom.mustache'))
        FileUtils.mkdir_p('templates')
        File.symlink(outside, 'templates/releases')
        configure_custom_output('templates/releases/custom.mustache')

        expect { run_since }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
          .and output(/must point to a file inside the project directory/).to_stderr
          .and output('').to_stdout
        expect(Dir.exist?('tmp')).to be false
      end
    end

    it 'aborts without writing output when custom_output is missing' do
      configuration.merge!('output_format' => ['custom'], 'templates' => { 'custom' => 'custom.mustache' })
      File.write('.whatsup.yml', configuration.to_yaml)

      expect { run_since }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        .and output(/'custom_output' is not set/).to_stderr
      expect(Dir.exist?('tmp')).to be false
    end
  end

  describe 'recorded GitHub API interactions' do
    it 'replays a public repository search without live network access' do
      configuration['labels']['required'] = ['documentation']
      File.write('.whatsup.yml', configuration.to_yaml)

      VCR.use_cassette('fetches_merged_pull_requests_for_a_real_public_repository',
                      allow_unused_http_interactions: false) do
        expect { run_since }.to output(/Done!/).to_stdout
      end

      expect(read_output['entries']).to eq([])
    end
  end
end
