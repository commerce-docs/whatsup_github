# whatsup_github

[![Gem version](https://img.shields.io/gem/v/whatsup_github.svg?style=flat)](https://rubygems.org/gems/whatsup_github)

This tool helps updating data for [Whats New on DevDocs](http://devdocs.magento.com/whats-new.html).
It filters GitHub pull requests and generates a data file.
One pull request sources one data entity.
All filtering parameters are set in a configuration file, except dates.
_Since_ date is set as a CLI argument and the _till_ date is always the moment when the command is run.

## CLI

```console
Commands:
  whatsup_github help [COMMAND]  # Describe available commands or one specific command
  whatsup_github since DATE      # Filters pull requests since the specified date till now. Default: last 7 days.
  whatsup_github version         # Current version of the gem

Usage:
  whatsup_github since DATE

Options:
  [--config=CONFIG]  # Relative path to the configuration file.
                     # Default: .whatsup.yml
```

## What's generated

A resulting YAML file `tmp/whats-new.yml` is generated from GitHub data.

### `description`

Text for `description` is taken from individual pull request's description (same as body).
The text must follow the `whatsnew` keyword and be located at the end.

Example:

```console
This pull request adds ...

Some other details about this pull request.

whatsnew
Added documentation about [New Magento feature](https://devdocs.magento.com/new-magento-feature.html).
```

### `type`

Set as a list of `labels` in `.whatsup.yml`. There are two types of labels in configuration:

- `required` are labels that must include `whatsnew`. Otherwise, resulting output will warn about missing `whatsnew`.
- `optional` are labels that may include `whatsnew`. If `whatsnew` is missing, you won't get any notification about this.

### `versions`

Any GitHub label that starts from a digit followed by a period like in regular expression `\d\.`.
Examples: `2.3.x`, `1.0.3-msi`, `2.x`

### `date`

Date when the pull request was merged.

### `link`

URL of the pull request. For repos with the `enterprise:` prefix, the link is
formatted as `enterprise:<org>/<repo>/pull/<number>` to avoid exposing the
internal hostname.

### `contributor`

An author of a pull request.

### `merge_commit`

Merge commit SHA of the pull request.

### `labels`

All labels added to the pull request.

## Installation

This gem can be installed as a system command-line tool or as a command-line tool available in a project.

### System installation

```bash
gem install whatsup_github
```

### Project installation

Add to your Gemfile:

```ruby
gem 'whatsup_github'
```

And install:

```bash
bundle
```

## Configuration

The default configuration file [`.whatsup.yml`](lib/template/.whatsup.yml) will be
created automatically after first run unless it's already there.

To use non-default location or name of the file, use the --config option. Example:

```shell
whatsup_github since 'apr 9' --config 'configs/whatsup_bp.yml'
```

## Authentication

Authentication is checked in this order: environment variables → `.env` file → `~/.netrc` → guest (rate-limited).

### With a .env file

Create a `.env` file in the directory where you run `whatsup_github`. See [`.env.example`](.env.example) for the format.

```bash
WHATSUP_GITHUB_ACCESS_TOKEN=<public-github-token>
WHATSUP_GITHUB_ENTERPRISE_HOSTNAME=<enterprise-hostname>
WHATSUP_ENTERPRISE_ACCESS_TOKEN=<enterprise-github-token>
```

### With environment variables

```bash
WHATSUP_GITHUB_ACCESS_TOKEN=askk494nmfodic68mk whatsup_github since 'apr 2'
```

`WHATSUP_GITHUB_ENTERPRISE_HOSTNAME` sets the hostname for GitHub Enterprise Server
(e.g. `git.example.com`). Optional for GHEC — defaults to `github.com`.

`WHATSUP_ENTERPRISE_ACCESS_TOKEN` is used for repos prefixed with `enterprise:` in
`.whatsup.yml`. Useful when you need two separate accounts — for example, a public
GitHub account and a GHEC org account.

### With the .netrc file

Use [`~/.netrc`](https://github.com/octokit/octokit.rb#using-a-netrc-file) for
authentication. See [`.netrc.example`](.netrc.example) for the format.

```config
machine api.github.com
  login <github-username>
  password <personal-access-token>
```

For GitHub Enterprise Server (self-hosted), add a second entry using the server hostname:

```config
machine git.enterprise.example.com
  login <enterprise-username>
  password <enterprise-personal-access-token>
```

> **Note:** `.netrc` only supports one entry per host. If you need two different
> accounts on `api.github.com` (e.g., public GitHub + GHEC), use `.env` or
> environment variables instead.

## Usage

```bash
whatsup_github since 'apr 2'
```

To use the default date range of the past 7 days, omit the date:

```bash
whatsup_github since
```

You can use different date formats like `'April 2'`, `'2 April'`, `'apr 2'`, `'2 Apr'`, `2018-04-02`.

## Development

To install dependencies:

```bash
bin/setup
```

To install the package:

```bash
rake install
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Testing

The project contains [rspec](https://rspec.info/) tests in `spec` and
cucumber tests in `features`.

#### specs

To run rspec tests:

```bash
rake spec
```

#### features

To run Cucumber tests:

```bash
rake features
```

To pass the `output_file.feature` tests, you need to generate a non-empty `whats-new.yml`.
To test just file:

```bash
bundle exec cucumber features/since.feature
```

NOTE: Cucumber tests will use the configuration file from code `lib/template/.whatsup.yml`.

#### Individual files

Individual files can have tests at the end of a file in a format like:

```ruby
if $PROGRAM_NAME == __FILE__
  # test code here
end
```

To run such test, run the corresponding file:

```bash
ruby lib/whatsup_github/config_reader.rb 
```

The tests use the root `.whatsup.yml` file to read configuration.

### Local testing against live GitHub data

The tool makes live GitHub API calls, so end-to-end local testing requires
real credentials and a real repository.

#### Set up credentials

Copy `.env.example` to `.env` and fill in your tokens:

```bash
cp .env.example .env
```

#### Use a narrow date range

A short window keeps the result set small and avoids burning API rate limits:

```bash
bundle exec whatsup_github since 'yesterday'
```

#### Check the output

Results are written to `tmp/whats-new.yml`. The `tmp/` directory is
gitignored, so test output won't be accidentally committed.

#### Debug search queries

To inspect the exact GitHub search queries being sent, run with `DEBUG=1`:

```bash
DEBUG=1 bundle exec whatsup_github since 'yesterday'
```

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
