# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added [hdbpp-ttl]
 - Report script result to rest reporting server

### Added [hdbpp-cluster-reporting]
 - PUT method for ttl reporting
 - information from ttl

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
