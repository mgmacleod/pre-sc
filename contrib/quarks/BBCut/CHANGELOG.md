## [2.2] - 2016-02-21

### Added
- Documented all cut effects.
- Added action argument to BBCutBuffer.
- Allowed arguments to CutFXSwap1 to be functions.
- Added errors when trying to run BBCut while the server isn't running.

### Changed
- Moved documentation to the new help system.
- Renamed example sounds with .aiff extensions.

### Removed
- Removed ugens, which have been moved to sc3-plugins.

### Fixed
- Fixed Segmentation bitrot.
- Imported missing class CampStream.
- Fixed bug where CutFXSwap1 would sometimes remove a CutMixer.