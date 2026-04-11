Feature: Since
  In order to get updates since some date
  As a CLI
  I want to get valid formatted content

Scenario: Basic
  Given a file named ".whatsup.yml" with:
    """
    ---
    base_branch: main
    repos:
      - octokit/octokit.rb
    labels:
      required:
        - enhancement
    output_format:
      - yaml
    magic_word: whatsnew
    """
  When I run `whatsup_github since 'jun 10'`
  Then the output should contain "Done!"

Scenario: Check version
  When I run `whatsup_github version`
  Then the output should contain "Current version is"

Scenario: With no subcommand or argument
  When I run `whatsup_github`
  Then the output should contain "Commands:"
