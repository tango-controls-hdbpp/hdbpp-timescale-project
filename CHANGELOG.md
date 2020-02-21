# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added [general]

* Updated create-test-database help display.
* Added a CMake project build system that can build all required elements for deployment. External elements are downloaded to external/
* Added hdbpp-health-check device server to the components.

### Chanaged [hdbpp-health-check]

* Cleaned up Clang warnings for HdbppHealthCheck.

### Changed [schema]

* Removed some duplicate indexes

### Changed [hdbpp-timescale-docker]

* Updated to TimescaleDB version 1.6