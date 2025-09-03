# Changelog

## 1.2.0

Maintenance:

- Upgraded octokit dependency from ~> 8.0 to ~> 10.0
- Upgraded cucumber dependency from ~> 9.1 to ~> 10.1
- Updated all dependencies to their latest compatible versions

## 1.0.1

Fixes:

- Fixed bug with missing whatsnew in enterprise repos

## 1.0.0

### General

- Major version release with significant updates
- Updated gemspec dependencies
- Updated Ruby requirement to >= 2.7.0
- Updated octokit to ~> 6.0
- Updated thor to ~> 1.2

### CLI improvements

- Added version CLI option
- Removed default option to make 'help' option default

### Testing

- Added test for 'version' CLI option
- Updated tests to run with rake by default
- Added code testing workflow
- Removed Travis CI workflow

### Bug fixes

- Fixed GitHub API query requirement to include 'is:pull-request'
- Updated search query as required by GitHub API

## 0.5.0

Fixes:

- Fixed bug "422 - Query must include 'is:issue' or 'is:pull-request'"

Maintenance:

- Updated gemspec dependencies
- Updated Ruby requirement to >= 2.7.0
- Updated octokit to ~> 6.0
- Updated thor to ~> 1.2
- Updated development dependencies (aruba, bundler, cucumber, rspec, fileutils, faraday-retry)

## 0.4.2

Fixes:

- Fixed a bug with non-working membership

Maintenance:

- Added code linting

## 0.4.1

- Added authentication via an environment variable `WHATSUP_GITHUB_ACCESS_TOKEN`

## 0.4.0

### General

- Loading more data about pull requests via API
- Loading data about configured organization members via API
- Upgraded gem specs
- Removed non-working tests. TODO: Add tests for the output file.

### New configuration option

Added `membership` to configuration. Value: name of an organization to check membership of a contributor.

### New output data

Added `merge_commit`, `labels`, and `membership` to YAML output.
Values for `membership`:
    - `true` if contributor is a member of the configured organization
    - `false` if not a member
    - empty if not configured

## 0.3.1

- Added `contributor` and `profile` output data.

## 0.3.0

- Added "magic word" to configuration file
- Added the requested GitHub query to terminal output (#13)
- Fixed the issue with empty description (#21)

## 0.2.0

- Implemented two types of labels in configuration: 'optional' and 'required'.

## 0.0.1

The tool is released as a gem.
