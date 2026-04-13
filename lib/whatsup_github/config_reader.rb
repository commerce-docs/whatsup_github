# frozen_string_literal: true

require 'yaml'
require 'singleton'
require 'fileutils'

module WhatsupGithub
  # Creates readable objects from confirurarion files
  class Config
    attr_reader :config

    include Singleton

    @@filename = ''

    def self.filename=(filename)
      if filename.include?('..') || filename.start_with?('/')
        abort "ERROR: Invalid config path '#{filename}'"
      end
      @@filename = filename
    end

    def initialize
      @file = File.expand_path(@@filename, Dir.pwd)
      @config = {}
    end

    def read
      unless File.exist?(@file)
        dist_file = File.expand_path("../template/#{File.basename(@file)}", __dir__)
        FileUtils.cp dist_file, @file
      end
      @config = YAML.safe_load(File.read(@file), permitted_classes: [Symbol])
      return {} unless @config

      @config
    end

    def repos
      read['repos']
    end

    def base_branch
      read['base_branch']
    end

    def output_format
      read['output_format']
    end

    def labels
      required_labels + optional_labels
    end

    def required_labels
      res = read.dig 'labels', 'required'
      return [] unless res

      res
    end

    def optional_labels
      res = read.dig 'labels', 'optional'
      return [] unless res

      res
    end

    def membership
      read['membership']
    end

    def magic_word
      read['magic_word']
    end
  end
end

if $PROGRAM_NAME == __FILE__
  config = WhatsupGithub::Config.instance
  p config.repos
  p config.base_branch
  p config.output_format
  p config.labels
  p config.required_labels
  p config.optional_labels
  p config.magic_word
  p config.membership
end
