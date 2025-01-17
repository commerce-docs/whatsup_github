# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'whatsup_github/version'

Gem::Specification.new do |spec|
  spec.name          = 'whatsup_github'
  spec.version       = WhatsupGithub::VERSION
  spec.authors       = ['Dima Shevtsov']
  spec.email         = ['shevtsov@adobe.com']

  spec.summary       = 'Collect info from GitHub pull requests.'
  spec.homepage      = 'https://github.com/dshevtsov/whatsup_github'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/dshevtsov/whatsup_github'
    spec.metadata['changelog_uri'] = 'https://github.com/dshevtsov/whatsup_github/blob/master/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'netrc', '~> 0.11'
  spec.add_dependency 'octokit', '~> 8.0'
  spec.add_dependency 'thor', '~> 1.3'

  spec.add_development_dependency 'aruba', '~> 2.2'
  spec.add_development_dependency 'bundler', '~> 2.5'
  spec.add_development_dependency 'cucumber', '~> 9.1'
  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'fileutils', '~> 1.7'
  spec.add_development_dependency 'faraday-retry', '~> 2.2'
end
