# rswag

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

### Added

### Changed

### Documentation

## [2.10.1]

### Fixed

- Fix path expansion (https://github.com/rswag/rswag/pull/660)

## [2.10.0]

### Fixed

- Sanitize directory traversal in middleware (https://github.com/rswag/rswag/pull/654)
- Fix encoding of query params (https://github.com/rswag/rswag/pull/621)

### Added

- Allow passing metadata to HTTP verb methods (https://github.com/rswag/rswag/pull/628)
- Added configuration for RuboCop RSpec to improve detection of RSpec examples and example groups (https://github.com/rswag/rswag/pull/632)

### Changed

### Fixed

### Documentation

## [2.9.0]

### Added

- Added option --spec_path to the generator command with requests as default value (https://github.com/rswag/rswag/pull/607)
- Add support for `:getter` parameter option to explicitly define custom parameter getter method and avoid RSpec conflicts with `include` matcher and `status` method (https://github.com/rswag/rswag/pull/605)
- Added support strict schema validation and allow to pass metadata to run_test! (https://github.com/rswag/rswag/pull/604)
- Add support for passing a custom specification description to `run_test!` (https://github.com/rswag/rswag/pull/622)

### Changed

- Remove commented code (https://github.com/rswag/rswag/pull/576)

### Fixed

- Invalid URI error when specifying protocol within server configuration (https://github.com/rswag/rswag/pull/591)
- Fix ADDITIONAL_RSPEC_OPTS to always apply (https://github.com/rswag/rswag/pull/584)

### Documentation

- Ask for dependency versions in issue template (https://github.com/rswag/rswag/pull/575)

## [2.8.0]

### Added

- Add support for nullable & required on header parameters (https://github.com/rswag/rswag/pull/527)
- Add option to set `Host` in header (https://github.com/rswag/rswag/pull/570)
- Add Support for Request body examples (https://github.com/rswag/rswag/pull/555)

### Changed

### Fixed

- Fix support for referenced parameter schema https://github.com/rswag/rswag/pull/564)

### Documentation

- Correct method name in ReadMe (https://github.com/rswag/rswag/pull/566)

## [2.7.0]

### Added

- Add tooling for measuring test coverage so that changes are safer (https://github.com/rswag/rswag/pull/551)
- Add CSP compatible with rswag in case the Rails one is not compatible (https://github.com/rswag/rswag/pull/263)
- Add ADDITIONAL_RSPEC_OPTS env variable (https://github.com/rswag/rswag/pull/556)
- Add option to set Host header (https://github.com/rswag/rswag/pull/184)

### Changed

- Change default dev tooling setup to Ruby 2.7 and Rails 6 (https://github.com/rswag/rswag/pull/542)
- Make the development docker user non-root for easier volume sharing (https://github.com/rswag/rswag/pull/550)
- Update `json-schema` dependency version constraint (https://github.com/rswag/rswag/pull/517)
- Add deprecation notice for intent to drop support for Ruby 2.6 and RSpec 2 (https://github.com/rswag/rswag/pull/552)

### Fixed

- Fix request body examples (https://github.com/rswag/rswag/pull/555)
- Corrected method name in README example (https://github.com/rswag/rswag/pull/566)
- Fix Style/SingleArgumentDig issue in `swagger_formatter` (https://github.com/rswag/rswag/pull/486)
- Make dependency on rspec-core explicit instead of implied (https://github.com/rswag/rswag/pull/554)
- Fix base path for OAS3 specification (https://github.com/rswag/rswag/pull/547)
- Fix ResponseValidator adding support for nullable and required headers (https://github.com/rswag/rswag/pull/527)

### Documentation

## [2.6.0] - 2022-09-09

### Added

- Examples generated with `run_test!` now have the rspec tag `rswag`
- Add query parameter serialization styles (OAS3) (https://github.com/rswag/rswag/pull/507)
- Support for adding descriptions in body params (https://github.com/rswag/rswag/pull/422)
- Display all validation errors instead of only the first (https://github.com/rswag/rswag/pull/461)

## Fixed

- Fixes examples for OAS3 specification, allowing multiple examples (https://github.com/rswag/rswag/pull/501)
- Fix array parameter serialization on OAS3 (https://github.com/rswag/rswag/pull/507)
- Fix assorted spelling errors (https://github.com/rswag/rswag/pull/535)
- Fix null-checking when using a referenced property (https://github.com/rswag/rswag/pull/515)

### Changed

- Rename generated `rswag-ui.rb` file to match Ruby style (https://github.com/rswag/rswag/pull/508)
- Code comment formatting changes (https://github.com/rswag/rswag/pull/487)

### Documentation

- Add Syntax Highlighting to ReadMe (https://github.com/rswag/rswag/pull/525/files)
- Fix ReadMe response headers example for OpenApi3.0 (https://github.com/rswag/rswag/pull/518)
- Update TOC in the ReadMe (https://github.com/rswag/rswag/pull/536/files)
- Fix incorrect sample code for example generation (https://github.com/rswag/rswag/pull/513)

## [2.5.1] - 2022-02-10

### Fixed

- Fixed missing assets in rswag-ui [#493](https://github.com/rswag/rswag/pull/493)

## [2.5.0] - 2022-02-08

### Added

- Update swagger-ui to 3.52.5 [#453](https://github.com/rswag/rswag/pull/453)
- Added specs print failed body [#406](https://github.com/rswag/rswag/pull/406)
- Added ability to specify multiple params in short form [#300](https://github.com/rswag/rswag/pull/300)
- REVERTS #300, help wanted! [#407](https://github.com/rswag/rswag/pull/407)
- Added better messages for missing lets [#441](https://github.com/rswag/rswag/pull/441)
- Added Rails 7.0 support [#450](https://github.com/rswag/rswag/pull/450)

### Fixed

- Fixed allowed $refs in components [#404](https://github.com/rswag/rswag/pull/404)

### Documentation

- Documents support for multiple tags [#416](https://github.com/rswag/rswag/pull/416)
- Documents libv8 troubleshooting [#426](https://github.com/rswag/rswag/pull/426)

### Development

- Development - Replaces TheRubyRacer with mini_racer [#442](https://github.com/rswag/rswag/pull/442)
- Development - Migrate to GH Action for tests [#475](https://github.com/rswag/rswag/pull/475)
- Development - Test improvements[#481](https://github.com/rswag/rswag/pull/481)

## [2.4.0] - 2021-02-09

### Added

- Added `SWAGGER_DRY_RUN` env variable [#274](https://github.com/rswag/rswag/pull/274)

## [2.3.3] - 2021-02-07

### Fixed

- Include response examples [#394](https://github.com/rswag/rswag/pull/394)

### Changed

- Update swagger-ui to 3.42.0

## [2.3.2] - 2021-01-27

### Added

- RequestBody now supports the `required` flag [#342](https://github.com/rswag/rswag/pull/342)

### Fixed

- Fix response example rendering [#330](https://github.com/rswag/rswag/pull/330)
- Fix empty content block [#347](https://github.com/rswag/rswag/pull/347)

## [2.3.1] - 2020-04-08

### Fixed

- Remove require for byebug [#295](https://github.com/rswag/rswag/issues/295)

## [2.3.0] - 2020-04-05

### Added

- Support for OpenAPI 3.0 ! [#286](https://github.com/rswag/rswag/pull/286)
- Custom headers in rswag-api [#187](https://github.com/rswag/rswag/pull/187)
- Allow document: false rspec meta-tag [#255](https://github.com/rswag/rswag/pull/255)
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
