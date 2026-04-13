# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Language picker in auth page
- Custom Drinks can now be deleted
- BeerWithMe data import

### Changed
- Branding
  - New icons for feed and statistics
  - Improved splash screen
  - Added theme-color for mobile browsers
  - Bigger app bar titles
  - apk builds are now named glasstrail-vX.X.X-release.apk
- Refactor: Renamed HistoryScreen to FeedScreen
- Removed the backend info card from the profile screen
- Highlight delete and remove actions in red
- added dedicated routes for statistics and bar tabs
- Category chips in statistics are now only shown when corresponding data is available
- refactor statistics screen files
- Moved logout button above roadmap info

### Fixed
- Fix warning in web regarding missing emoji font subset
- Center the bar custom drinks empty state card
- Removing a photo from a custom drink now also deletes the image from DB
- Keep custom drink edit dialogs from overflowing when a photo preview is shown

## [1.1.0] - 2026-04-10
### Added
- Changelog
  - Changelog card in feed appears when app was updated
  - Permanent link to changelog in about page
- Included 🍺 in attribution about page
- Overhauled Readme
- Proper empty states for statistics history and custom drinks
- More global drinks and categories added
- GNU License added

### Changed
- German translations improved
- Agents file adapted

### Security
- Restrict read access for global categories and global drinks to authenticated users only

## [1.0.1] - 2026-03-29
### Added
- First android app release via Github Releases!
- CI/CD Pipelines set up
- Initial app version
  - feed
  - statistics, map, gallery, streaks
  - profile
  - add drink
  - settings
  - login

[Unreleased]: https://github.com/donjoergo/glasstrail/compare/1.1.0...HEAD
[1.1.0]: https://github.com/donjoergo/glasstrail/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/donjoergo/glasstrail/releases/tag/1.0.1
