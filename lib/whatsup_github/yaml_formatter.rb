# frozen_string_literal: true

require 'yaml'

module WhatsupGithub
  # Table containing Rows
  class YAMLFormatter
    def generate_output_from(content)
      output =
        {
          'updated' => Time.now.strftime('%c').tr_s(' ', ' '),
          'entries' => content.collect(&:to_h)
        }
      output.to_yaml
    end
  end
end
