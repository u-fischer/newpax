# Changelog
All notable changes to the `newpax`  since the
first release 0.5, 2021-02-23 will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
this project uses date-based 'snapshot' version identifiers.

## [2025-08-21]
Version 0.56

### Fixed
 - handle GoTo links which use /Dest (string), issue #27

### Changed
 - adapt to changes in LaTeX for \DocumentMetadata
 
## [2023-11-08]
Version 0.55

### Fixed

 - sort destinations by name (issue #26, PR #25)
 - handling of inline /Dest entries, issue #24
 
## [2023-09-11]
Version 0.54

### Changed
- destinations now use the names derived from the original names if possible. 
- more destinations are extracted.

Both allows to reference them from the "outside", see issue #20,

### Fixed
- spurious spaces
- wrong coordinate for unnamed destinations 
 
## [2022-09-15]
### Fixed

- URI values given as indirect object (issue #18)
 

## [2022-09-11]

### Fixed
 - error if CreationDate not  found, issue #15
 - error if there no info dictionary at all, issue #17
 - fixed error if F in GoToR is an indirect object

## [2022-06-27]

### Fixed 

 - add a missing test, issue #10
 - handle escaped parentheses in url's, issue #9
 - handle filespec dictionaries
  - GotoR annotations if filespec is a simple file name
 
## [2021-03-07]

### Added

### Changed
- Adapted \pdfannot_box: to changes in pdfmanagement.

### Removed

### Fixed
- allow # and % in url: issue #3
- better error message if pdf is not found by luascript issue #1
- some documentation clarifications

## [2021-02-23]

First release
