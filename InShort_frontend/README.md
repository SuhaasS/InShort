# InShort: Personalized U.S. Bills News App

InShort is an iOS app that fetches and summarizes federal bills in plain English, personalized by user profile (age, location, interests). It lets users discover, discuss, and engage with legislation that matters to them.

## Features

### News Tab
- **All Bills**: Scrollable list of latest bills with party affiliation badges
- **My Feed**: Personalized feed based on user interests, age, and location
- Like/dislike bills to influence your feed
- Subscribe to bills to receive notifications when they update
- Email representatives directly from the app

### Chat Tab
- Ask questions about specific bills or legislation in general
- AI-powered assistant provides plain-English explanations
- Select bills to discuss from a searchable list

### Profile Tab
- Edit your name, age, location, and interests
- Manage bill subscriptions
- View your friends' activity in the Friends Feed
- Customize your experience to see legislation that matters to you

## Technical Details

### Architecture
- SwiftUI for the UI
- MVVM architecture with ObservableObject view models
- Combine for reactive programming
- Async/await for asynchronous operations
- SwiftData for persistence

### Data Sources
The app can work with two data sources:
- **Debug Mode**: Uses locally bundled JSON fixtures
- **Production Mode**: Calls service methods that can be connected to a real backend

Toggle between these modes using the `DEBUG_USE_FAKE_DATA` constant.

### Key Components
- **Models**: Bill, UserProfile
- **ViewModels**: NewsViewModel, ChatViewModel, ProfileViewModel, FriendsViewModel
- **Services**: BillService, UserService, NotificationService, LLMChatService
- **Views**: Organized by feature (News, Chat, Profile, Friends)

## Running the App

1. Open the project in Xcode 15 or later
2. Copy `Constants.swift.template` to `Constants.swift` if it doesn't exist
3. Customize the API endpoints in `Constants.swift` as needed
4. Select a simulator or device
5. Build and run the app

By default, the app runs in debug mode with fake data. To switch to production mode, change the `DEBUG_USE_FAKE_DATA` constant in `Constants.swift` to `false`.

## Configuration

The app uses an xcconfig file for configuration to avoid hardcoding sensitive or environment-specific values in the source code.

### Setting up the configuration file

1. Copy the template configuration file:
   ```
   cp Constants.swift.template Constants.swift
   ```

2. Edit `Constants.swift` to set your specific configuration values:
   ```
   // API Endpoints
   RECOMMENDATIONS_API_URL = https://your-api-server.com/recommendations/
   ```

The `Constants.swift` file is excluded from git to allow each developer to use their own configuration without affecting others.

## Accessibility

InShort is designed to be accessible to all users:
- Supports Dynamic Type for adjustable text sizes
- VoiceOver compatible with descriptive labels and hints
- Proper color contrast for readability
- Adaptive layout for different device sizes

## Future Enhancements

- Deep linking to specific bills
- Social sharing of bills
- More advanced filtering and search options
- Integration with real legislative data APIs
- Push notifications for bill updates
