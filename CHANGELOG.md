# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

### Added

- Initial release
- `XCResultParser` for parsing xcresult bundles
- Build results parsing (warnings, errors, analyzer warnings)
- Test results parsing with failure extraction
- Source location parsing from both build issues and test failures
- Resilient enum decoding for forward compatibility with future Xcode versions
- Comprehensive test suite with fixtures
