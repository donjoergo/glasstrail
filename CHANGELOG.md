# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Full desktop mode: adaptive widescreen layouts with resizable master-detail views, a floating map detail panel, dialogs instead of sheets, and multi-pane statistics and bar screens
- Map toggles for cluster and photo and locate-me button
- Reset a drink category's sort order back to alphabetical, and pull-to-refresh on the bar screen

### Fixed
- Directly creating and logging of custom drinks with images is now more intuitive
- Drinks now sort alphabetically regardless of letter case

## [2.2.0] - 2026-07-11
### Added
- Startup and media caching for faster signed-in launches
- Tap profile photo to view fullscreen
- Maintenance: Enabled dependabot

### Changed
- Prevent un-cheering action

### Fixed
- Harden cache cleanup on session changes
- About app attribution localized

## [2.1.0] - 2026-05-25
### Added
- Prompt BeerWithMe import after sign-up
- Profile account management: Delete account and change password

### Changed
- Build only arm64 apk to reduce app size from 100mb to \~ 35mb

### Fixed
- Feed was sometimes stuck on scrolling
- Chrome Mobile: Keep web theme color after sign-in
- Localize startup loading text
- Statistics map now uses native MapLibre markers with sharper pins and more reliable alignment, clustering, hover, and tap behavior

## [2.0.0] - 2026-05-11
### Added
- Social & Friends
  - Public profile page which can be shared with friends
  - Public profile link has a nice messenger preview
  - Accept/decline/withdraw friend requests
  - Friend profile statistics screen
  - Deep linking: profile links open the Glass Trail app when installed, otherwise they show the web version
  - Feed: See drink entries from friends
  - Feed: Cheers reactions on drinks
- Notifications
  - Added dedicated notifications screen
  - Push notifications are now being created for the following events:
    - friend logged a new drink
    - friend cheered one of your drinks
    - friend request sent
    - friend request accepted
    - friend request rejected
    - friend removed
- Track alcohol-free beer separately in drink metadata and statistics.
- Added SonarQube analysis
- Feed cheers reactions with notifications
- Feed: change drink type while editing entries

### Fixed
- Fix map under Android

## [1.2.1] - 2026-04-13
### Fixed
- Fix failing tests in CI pipeline
- apk now correctly named glasstrail-vX.X.X-release.apk

## [1.2.0] - 2026-04-13
### Added
- Language picker in auth page
- Custom Drinks can now be deleted
- BeerWithMe data import
- Added non-alcoholic beer, mate tea and club-mate to global drinks
- Statistics overview now includes an all-time total card

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
- Added dedicated routes for statistics and bar tabs
- Category chips in statistics are now only shown when corresponding data is available
- Refactor statistics screen files
- Moved logout button above roadmap info
- Default new custom drinks to beer in the custom drink dialog.

### Fixed
- Fix warning in web regarding missing emoji font subset
- Center the bar custom drinks empty state card
- Removing a photo from a custom drink now also deletes the image from DB
- Keep custom drink edit dialogs from overflowing when a photo preview is shown
- Show the year for best streaks outside the current year

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

[Unreleased]: https://github.com/donjoergo/glasstrail/compare/2.2.0...HEAD
[2.2.0]: https://github.com/donjoergo/glasstrail/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/donjoergo/glasstrail/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/donjoergo/glasstrail/compare/1.2.1...2.0.0
[1.2.1]: https://github.com/donjoergo/glasstrail/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/donjoergo/glasstrail/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/donjoergo/glasstrail/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/donjoergo/glasstrail/releases/tag/1.0.1
