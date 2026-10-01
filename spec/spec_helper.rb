# frozen_string_literal: true

require 'simplecov'

require 'bundler/setup'
require 'webmock/rspec'
require 'whatsup_github'
require_relative 'support/singleton_helper'
require_relative 'support/netrc_helper'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include SingletonHelper
  config.include NetrcHelper

  config.before do
    reset_singleton!(WhatsupGithub::Config)
    reset_singleton!(WhatsupGithub::Client)
    reset_singleton!(WhatsupGithub::EnterpriseClient)
  end
end
