# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added [hdbpp-cluster-reporting]
 - Aggregate size
 - Aggregate row count per type and interval

### Added [decimation]
 - Schema for the aggregates view for scalar data.
   aggregates avg, min, max, stddev over a year.
   for floating point data, nan and infinity values are
   counted and not taken into account

### Fixed [hdbpp-cluster-reporting]
 - Block the version for the dependency Werkzeug as new
   version breaks flaskrestplus


## [0.1.0] - 2020-01-05

### Added [hdbpp-cluster-reporting]
 - Database size
 - Attributes count, per type and format
 - Tables size
 - Last chunk size
 - Chunk interval size
 - Tables row count

### Changed [hdbpp-reorder-chunks]
 - Do not reorder last chunk
 - Nor the already ordered chunks 

### Removed [hdbpp-reorder-chunks]
 - Schedule window, we keep track of ordered chunks
