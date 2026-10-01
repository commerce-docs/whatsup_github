# frozen_string_literal: true

require 'mustache'

module WhatsupGithub
  # Renders rows through a project-supplied Mustache template (output_format: custom)
  class CustomFormatter
    def generate_output_from(content)
      path = resolved_template_path
      rows = content.map(&:to_h)
      Mustache.render(File.read(path), 'rows' => rows)
    end

    private

    def resolved_template_path
      configured = Config.instance.template_path
      abort "ERROR: 'templates.custom' is not set in your configuration file." if configured.nil? || configured.empty?

      root = File.expand_path(Dir.pwd)
      full_path = File.expand_path(configured, root)
      root_prefix = root.end_with?(File::SEPARATOR) ? root : "#{root}#{File::SEPARATOR}"

      unless full_path.start_with?(root_prefix)
        abort "ERROR: 'templates.custom' must point to a file inside the project directory (got: '#{configured}')."
      end

      root = File.realpath(root)
      canonical_path = File.realpath(full_path)
      root_prefix = root.end_with?(File::SEPARATOR) ? root : "#{root}#{File::SEPARATOR}"

      unless canonical_path.start_with?(root_prefix)
        abort "ERROR: 'templates.custom' must point to a file inside the project directory (got: '#{configured}')."
      end
      abort "ERROR: Template file not found: '#{full_path}'" unless File.file?(canonical_path)

      canonical_path
    rescue SystemCallError
      abort "ERROR: Template file not found: '#{full_path || configured}'"
    end
  end
end
