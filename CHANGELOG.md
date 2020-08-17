# rswag
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

## [2.3.1] - 2020-04-08
### Fixed
- Remove require for byebug [#295](https://github.com/rswag/rswag/issues/295)

## [2.3.0] - 2020-04-05
### Added
- Support for OpenAPI 3.0 ! [#286](https://github.com/rswag/rswag/pull/286)
- Custom headers in rswag-api [#187](https://github.com/rswag/rswag/pull/187)
- Allow document: false rspec metatag [#255](https://github.com/rswag/rswag/pull/255)
- Add parameterized pattern for spec files [#254](https://github.com/rswag/rswag/pull/254)
- Support Basic Auth on rswag-ui [#167](https://github.com/rswag/rswag/pull/167)

### Changed
- Update swagger-ui version to 3.23.11 [#239](https://github.com/rswag/rswag/pull/239)
- Rails constraint moved from < 6.1 to < 7 [#253](https://github.com/rswag/rswag/pull/253)
- Swaggerize now outputs base RSpec text on completion to avoid silent failures [#293](https://github.com/rswag/rswag/pull/293)
- Update swagger-ui version to 3.28.0

## [2.2.0] - 2019-11-01
### Added
- New swagger_format config option for setting YAML output [#251](https://github.com/rswag/rswag/pull/251)
### Changed
- rswag-api will serve yaml files as yaml [#251](https://github.com/rswag/rswag/pull/251)

## [2.1.1] - 2019-10-18
### Fixed
- Fix incorrect require reference for swagger_generator [#248](https://github.com/rswag/rswag/issues/248)

## [2.1.0] - 2019-10-17
### Added
- New Spec Generator [#75](https://github.com/rswag/rswag/pull/75)
- Support for Options and Trace verbs; You must use a framework that supports this, for Options Rails 6.1+ Rails 6 does not support Trace. [#237](https://github.com/rswag/rswag/pull/75)
### Changed
- Update swagger-ui to 3.18.2 [#240](https://github.com/rswag/rswag/pull/240)

## [2.0.6] - 2019-10-03
### Added
- Support for Rails 6 [#228](https://github.com/rswag/rswag/pull/228)
- Support for Windows paths [#176](https://github.com/rswag/rswag/pull/176)
### Changed
- Show response body when error code is not expected [#117](https://github.com/rswag/rswag/pull/177)

## [2.0.5] - 2018-07-10
