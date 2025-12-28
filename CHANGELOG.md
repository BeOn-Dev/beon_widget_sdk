# Changelog

## [1.0.4] - 2025-12-28

### Fixed
- Remove incorrect @override annotations from ReactModel and LibraryModel
- Remove unused url_launcher import
- Remove unnecessary library name declaration

## [1.0.3] - 2025-12-28

### Added
- API error logging interceptor for debugging failed requests

### Fixed
- Fix dart analyze warning for Message class immutability (make fields final)
- Replace deprecated withOpacity() with withValues() method

## [1.0.2] - 2025-12-22

### Changed
- Updated repository URL to new location

## [1.0.1] - 2025-12-22

### Fixed
- Disabled console logging in production build
- Removed debug output from API calls and WebSocket events

## [1.0.0] - 2025-12-16

### Added
- Initial release of Beon Widget SDK
- **BeonChatWidget** - Main embeddable chat widget
- **Pre-chat form** - Collect visitor name, phone, and initial message
- **Real-time messaging** via Laravel Reverb WebSocket
- **Polling fallback** when WebSocket is unavailable
- **Visitor persistence** with device/browser fingerprinting
- **File attachments** support
- **Emoji picker** integration
- **Sound notifications** for new messages
- **Customizable theming** (colors, position, header text)
- **RTL/LTR support** for multi-language applications
- **Message caching** for offline support
- **Pagination** for loading message history

### Configuration
- Script tag parsing for web embedding
- Programmatic configuration via `BeonConfig`
- Position options: bottomRight, bottomLeft, topRight, topLeft
- Customizable header title and subtitle
- Welcome message support

### State Management
- Built with Flutter Riverpod
- Separate widget state (open/closed, view mode)
- Chat state (messages, loading, sending)
- Connection state monitoring

### API Integration
- Dio-based HTTP client with interceptors
- Authentication header management
- Retry logic for failed requests
- Message history fetching with pagination
- Message sending with metadata
