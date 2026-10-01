# frozen_string_literal: true

require 'fileutils'
require_relative 'generator'
require_relative 'config_reader'
require_relative 'yaml_formatter'
require_relative 'table'
require_relative 'custom_formatter'

module WhatsupGithub
  class Runner
    def initialize(date)
      @generator = Generator.new date
      @config = Config.instance
      @content ||= @generator.content
    end

    def run
      format = @config.output_format
      raise 'Cannot find "output_format" in config.yml' unless format

      table if format.include? 'markdown'
      data if format.include? 'yaml'
      custom if format.include? 'custom'
    end

    def write_results(file, formatter)
      formatted_content = @generator.run formatter, @content
      check_dir_at File.dirname file
      File.write file, formatted_content
      puts "Done!\nOpen \"#{file}\" to see the result."
    end

    def check_dir_at(filepath)
      FileUtils.mkdir_p filepath unless Dir.exist? filepath
    end

    def table
      write_results 'tmp/whats-new-on-devdocs.md', Table.new
    end

    def data
      write_results 'tmp/whats-new.yml', YAMLFormatter.new
    end

    def custom
      output = @config.custom_output
      abort "ERROR: 'custom_output' is not set in your configuration file." if output.nil? || output.empty?

      write_results output, CustomFormatter.new
    end
  end
end
