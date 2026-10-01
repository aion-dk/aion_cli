# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Address lookups now use Datafordeler (DAR/DAGI GraphQL) and Adressevask instead of DAWA
  (`api.dataforsyningen.dk`), which is being decommissioned. `AionCLI::DAWAClient` is replaced by
  `AionCLI::DatafordelerClient`. The `aion dawa` commands and the `DAWA-GUID` output column are
  unchanged, so files produced by `validate_address` still import into Logins.
- Configurable via `DATAFORDELER_GRAPHQL_BASE_URL`, `DATAFORDELER_API_KEY`, `DATAFORDELER_DAR_VERSION`,
  `DATAFORDELER_DAGI_VERSION`, `ADRESSEVASK_BASE_URL` and `ADRESSEVASK_TOKEN`.

### Removed
- `address_by_guid`, `address_string` and `address_object_to_s`, which were unused and have no
  direct equivalent in DAR.

## [0.2.8] - 2020-06-26
### Added
- Functionality to convert a CPR extract file into a csv file. 

### Changed
- Updated CHANGELOG.md to the new format.

## [0.2.7] - 2017-09-12
- Added task 'filter_cpr' to be able to filter records with a set of CPRs
 
[Unreleased]: https://github.com/aion-dk/aion_cli/compare/v0.2.8...HEAD
[0.2.8]: https://github.com/aion-dk/aion_cli/releases/tag/v0.2.8
