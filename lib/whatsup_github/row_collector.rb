# frozen_string_literal: true

require_relative 'row'
require_relative 'pulls'
require_relative 'config_reader'

module WhatsupGithub
  # Creates Row objects for the future table
  class RowCollector
    attr_reader :repos, :since

    def initialize(args = {})
      @repos = config.repos
      @since = args[:since]
    end

    def collect_rows
      rows = []
      repos.each do |repo|
        rows << collect_rows_for_a(repo)
      end
      rows.flatten
    end

    def collect_rows_for_a(repo)
      pulls(repo).map do |pull|
        Row.new(
          pr_number: pull.number,
          pr_title: pull.title,
          pr_body: pull.body,
          date: pull.merged_at,
          pr_labels: label_names(pull.labels.nodes),
          assignee: assignee(pull.assignees.nodes),
          merge_commit_sha: pull.merge_commit&.oid,
          author: pull.author&.login,
          author_url: pull.author&.url,
          pr_url: pr_url(repo, pull)
        )
      end
    end

    def sort_by_date
      collect_rows.sort_by do |c|
        Date.parse(c.date)
      end.reverse
    end

    private

    def pr_url(repo, pull)
      return pull.url unless repo.start_with?('enterprise:')

      "enterprise:#{repo.delete_prefix('enterprise:')}/pull/#{pull.number}"
    end

    def assignee(assignees)
      if assignees.empty?
        'NOBODY'
      else
        assignees.map(&:login).join(', ')
      end
    end

    def label_names(labels)
      labels.map(&:name)
    end

    def pulls(repo)
      Pulls.new(repo:, since:).data
    end

    def config
      Config.instance
    end
  end
end
