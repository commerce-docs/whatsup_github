# frozen_string_literal: true

require 'mustache'
require_relative 'row_collector'

module WhatsupGithub
  # Table containing Rows
  class Table
    TEMPLATE = File.read(File.expand_path('../template/table.mustache', __dir__))

    def generate_output_from(content)
      rows = content.collect do |object|
        {
          'description' => object.description,
          'versions' => object.versions,
          'type' => object.type,
          'date' => object.date
        }
      end
      Mustache.render(TEMPLATE, 'rows' => rows).tr_s(' ', ' ')
    end
  end
end
